#!/usr/bin/env python3
"""Lock a Modrinth modpack: <pack>/mods.json -> <pack>/modrinth.index.json.

mods.json lists Modrinth project slugs; this resolves each one (plus its required dependencies)
to the newest version for the pack's Minecraft version and loader, and writes a standard
.mrpack index with download URLs and sha512 hashes. Nix reads that file to fetch the server's
mods, and zips it into the client .mrpack (Modrinth App / Prism: "Import modpack").

Run it on a machine with internet access, then commit the result:

    nix shell nixpkgs#python3 -c python3 modules/homelab/minecraft/update-modpack.py \
        modules/homelab/minecraft/oneblock

Standard library only. Exit status is non-zero if a mod has no compatible version, unless it is
marked "optional" in mods.json (then it is left out with a warning, and you can drop it or try
again later). Optional only covers the mod itself: if it needs a library with no compatible
version, it is left out too.
"""

import json
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

API = "https://api.modrinth.com/v2"
USER_AGENT = "t-wilkinson/nixos-config (homelab modpack lock)"

# mrpack "dependencies" key for each loader
LOADER_KEYS = {
    "fabric": "fabric-loader",
    "quilt": "quilt-loader",
    "neoforge": "neoforge",
    "forge": "forge",
}


def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=30) as res:
            return json.load(res)
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None
        raise


def env_value(side):
    # Modrinth project sides: required / optional / unsupported / unknown.
    # mrpack env allows required / optional / unsupported.
    return side if side in ("required", "optional", "unsupported") else "required"


class Resolver:
    def __init__(self, game_version, loader, overrides):
        self.game_version = game_version
        self.loader = loader
        self.overrides = overrides  # slug -> {"side": "client"|"server"|"both"}
        self.projects = {}  # project id -> project
        self.files = {}  # project id -> mrpack file entry
        self.missing = []

    def project(self, ref):
        p = get(f"{API}/project/{urllib.parse.quote(ref)}")
        if p:
            self.projects[p["id"]] = p
        return p

    def versions(self, project_id):
        q = urllib.parse.urlencode(
            {
                "loaders": json.dumps([self.loader]),
                "game_versions": json.dumps([self.game_version]),
            }
        )
        return get(f"{API}/project/{project_id}/version?{q}") or []

    def pick(self, versions):
        # Newest release, else newest beta/alpha (the API lists newest first)
        for kind in ("release", "beta", "alpha"):
            for v in versions:
                if v["version_type"] == kind:
                    return v
        return None

    def add(self, ref, why, optional=False, version_id=None):
        p = self.projects.get(ref) or self.project(ref)
        if p is None:
            self.missing.append((ref, why, optional, "no such project"))
            return
        if p["id"] in self.files:
            return
        if p["project_type"] != "mod":
            print(f"  note: {p['slug']} is a {p['project_type']}, adding it like a mod")

        if version_id:
            v = get(f"{API}/version/{version_id}")
        else:
            v = self.pick(self.versions(p["id"]))
        if v is None:
            self.missing.append(
                (p["slug"], why, optional, f"no {self.loader} {self.game_version} version")
            )
            return

        f = next((f for f in v["files"] if f["primary"]), v["files"][0])
        client, server = env_value(p["client_side"]), env_value(p["server_side"])
        side = self.overrides.get(p["slug"], {}).get("side")
        if side == "client":
            server = "unsupported"
        elif side == "server":
            client = "unsupported"

        self.files[p["id"]] = {
            "path": f"mods/{f['filename']}",
            "hashes": {"sha1": f["hashes"]["sha1"], "sha512": f["hashes"]["sha512"]},
            "env": {"client": client, "server": server},
            "downloads": [f["url"]],
            "fileSize": f["size"],
        }
        print(f"  {p['slug']:32} {v['version_number']:24} client={client:11} server={server}")

        for dep in v.get("dependencies", []):
            if dep["dependency_type"] != "required" or not dep.get("project_id"):
                continue
            self.add(
                dep["project_id"],
                f"required by {p['slug']}",
                optional=optional,
                version_id=dep.get("version_id"),
            )


def main():
    if len(sys.argv) != 2:
        sys.exit(f"usage: {sys.argv[0]} <pack directory containing mods.json>")
    pack = Path(sys.argv[1])
    spec = json.loads((pack / "mods.json").read_text())

    game_version, loader = spec["minecraft"], spec["loader"]
    # The server runs this exact loader (nix-minecraft must have it: see its
    # pkgs/fabric-servers/loader_locks.json), and clients get it from the .mrpack
    loader_version = spec["loaderVersion"]

    mods = [m if isinstance(m, dict) else {"slug": m} for m in spec["mods"]]
    overrides = {m["slug"]: m for m in mods}
    print(f"Resolving {len(mods)} mods for {loader} {loader_version}, Minecraft {game_version}")

    r = Resolver(game_version, loader, overrides)
    for m in mods:
        optional = m.get("optional", False)
        before, missing = set(r.files), len(r.missing)
        r.add(m["slug"], "listed in mods.json", optional=optional)
        if optional and len(r.missing) > missing:
            # Something it needs has no compatible version: leave out everything it pulled in
            for pid in set(r.files) - before:
                print(f"  dropped {r.projects[pid]['slug']} (optional {m['slug']} is incomplete)")
                del r.files[pid]

    index = {
        "formatVersion": 1,
        "game": "minecraft",
        "versionId": spec["version"],
        "name": spec["name"],
        "summary": spec.get("summary", ""),
        "files": sorted(r.files.values(), key=lambda f: f["path"].lower()),
        "dependencies": {"minecraft": game_version, LOADER_KEYS[loader]: loader_version},
    }

    failed = False
    for slug, why, optional, reason in r.missing:
        level = "warning" if optional else "error"
        failed |= not optional
        print(f"{level}: {slug} ({why}): {reason}", file=sys.stderr)

    if failed:
        sys.exit(
            "Not written. Remove those mods from mods.json, mark them \"optional\", or pick a "
            "Minecraft version they all support."
        )

    out = pack / "modrinth.index.json"
    out.write_text(json.dumps(index, indent=2) + "\n")
    print(f"Wrote {out} ({len(index['files'])} files). Bump \"version\" in mods.json when you")
    print("change the mod list, so clients can tell the packs apart.")


if __name__ == "__main__":
    main()
