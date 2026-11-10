# modules/homelab/minecraft/packs.nix
#
# What each Minecraft server runs, as data. Used by mc-server.nix on the PC (server files) and on
# the Pi (the client modpack the dashboard offers for download). Nothing here is built unless a
# server or the dashboard uses it.
#
# A pack whose download hash is still null is left out (with a warning) until you fill it in:
#   nix store prefetch-file --json '<url from the warning>' | jq -r .hash
{ lib, pkgs }:
let
  escape = lib.replaceStrings [ "." ] [ "_" ];

  # CurseForge's CDN: files/<id / 1000>/<id % 1000>/<file name>
  curseforge =
    id: name:
    "https://mediafilez.forgecdn.net/files/${toString (id / 1000)}/${toString (lib.mod id 1000)}/${lib.escapeURL name}";

  # Unpacks a CurseForge zip and returns the folder that contains `marker`
  unpackTo =
    {
      name,
      src,
      marker,
    }:
    pkgs.runCommand name { nativeBuildInputs = [ pkgs.unzip ]; } ''
      unzip -q ${src} -d src
      found=$(find src -name ${lib.escapeShellArg marker} -not -path '*/__MACOSX/*' -printf '%d %p\n' \
        | sort -n | head -n 1 | cut -d' ' -f2-)
      if [ -z "$found" ]; then
        echo "${name}: no ${marker} in the download" >&2
        find src -maxdepth 2 >&2
        exit 1
      fi
      cp -r "$(dirname "$found")" "$out"
    '';
in
{
  # The world you already have (Creative, Amplified, ...), on Paper. Nothing to download.
  paper = {
    label = "Paper";
    description = "Paper 1.21.11 · your existing worlds";
    icon = "mdi-cube-outline";
    ready = true;
    package = p: p.paperServers.paper-1_21_11;
  };

  # OneBlock Reborn (the 1.21.11 "Mounts of Mayhem" map by Gamerz_Riot) on Fabric, with the mods
  # locked in oneblock/modrinth.index.json. Players need the same mods: the dashboard offers
  # the client pack (oneblock.mrpack) for the Modrinth App or Prism Launcher.
  oneblock =
    let
      index = lib.importJSON ./oneblock/modrinth.index.json;
      gameVersion = index.dependencies.minecraft;
      loaderVersion = index.dependencies."fabric-loader";

      world = rec {
        version = "1.1.6";
        fileId = 5661118; # curseforge.com/minecraft/worlds/oneblock-reborn/files/7335453
        fileName = "OneBlock_Reborn_${version}.zip";
        url = curseforge fileId fileName;
        hash = "sha256-6zq+AFsOVTAEXqRi+Ft2QsJ9s5+Jm+hjzq1Z0KgaRSE="; # nix store prefetch-file --json '<url>' | jq -r .hash
      };

      serverSide = lib.filter (f: (f.env.server or "required") != "unsupported") index.files;
      locked = index.files != [ ];
    in
    {
      label = "OneBlock";
      description = "OneBlock Reborn ${world.version} · Fabric ${gameVersion} · lucky blocks";
      icon = "mdi-cube";
      ready = locked && world.hash != null;
      notReady =
        lib.optional (!locked)
          "lock its mods: python3 modules/homelab/minecraft/update-modpack.py modules/homelab/minecraft/oneblock"
        ++
          lib.optional (world.hash == null)
            "set world.hash in modules/homelab/minecraft/packs.nix (nix store prefetch-file --json '${world.url}' | jq -r .hash)";
      inherit gameVersion loaderVersion;

      package = p: p.fabricServers."fabric-${escape gameVersion}".override { inherit loaderVersion; };

      # mods/ for the server: every file the index doesn't mark server-unsupported
      serverFiles = pkgs.linkFarm "oneblock-server-files" (
        map (f: {
          name = f.path;
          path = pkgs.fetchurl {
            name = lib.strings.sanitizeDerivationName (baseNameOf f.path);
            url = builtins.head f.downloads;
            sha512 = f.hashes.sha512;
          };
        }) serverSide
      );

      world = unpackTo {
        name = "oneblock-reborn-${world.version}";
        src = pkgs.fetchurl {
          name = "oneblock-reborn-${world.version}.zip";
          inherit (world) url hash;
        };
        marker = "level.dat";
      };

      # The client pack: just the index (and overrides/, if you add one); the launcher downloads
      # the mods itself
      mrpack =
        pkgs.runCommand "wilkinson-oneblock-${index.versionId}.mrpack" { nativeBuildInputs = [ pkgs.zip ]; }
          ''
            cp ${./oneblock/modrinth.index.json} modrinth.index.json
            ${lib.optionalString (builtins.pathExists ./oneblock/overrides) "cp -r ${./oneblock/overrides} overrides"}
            find . -exec touch -d @315532800 {} +
            zip -qrX "$out" modrinth.index.json ${lib.optionalString (builtins.pathExists ./oneblock/overrides) "overrides"}
          '';
    };

  # All the Mods 10, from its official server files. Updating: bump version/fileId/fileName and
  # the NeoForge version from the release's changelog, then reset hash to null and prefetch.
  # On a version change the server replaces config/, defaultconfigs/, kubejs/ etc. with the
  # pack's (as ATM's update guide says to); the world is kept.
  atm10 =
    let
      release = rec {
        version = "8.4";
        minecraft = "1.21.1";
        neoforge = "21.1.265";
        fileId = 9366998; # curseforge.com/minecraft/modpacks/all-the-mods-10/files/9366998
        fileName = "ServerFiles-${version}.zip";
        url = curseforge fileId fileName;
        hash = "sha256-9rxWuz2dkqy0HySnpzZaDQQYEkijRk77PVMi4VpOT/U="; # nix store prefetch-file --json '<url>' | jq -r .hash  (about 1.2 GB)
      };

      # Mods in the server pack that break on this server, left out of its mods folder (matched
      # against jar file names, case-insensitively). Players keep them; these are client-side.
      #   crash.?assistant: Crash Assistant (a crash-report window for players) loads through an
      #     early service whose mixin config can't be read here, and NeoForge stops at startup:
      #     "The specified resource 'crash_assistant.mixins.json' was invalid or could not be read"
      serverExclude = [ "crash.?assistant" ];

      files = unpackTo {
        name = "atm10-server-${release.version}";
        src = pkgs.fetchurl {
          name = "atm10-server-${release.version}.zip";
          inherit (release) url hash;
        };
        marker = "mods";
      };

      # The pack's mods/ minus serverExclude. Fails if a pattern matches nothing (a renamed jar),
      # so the list can't silently go stale.
      serverMods = pkgs.runCommand "atm10-server-mods-${release.version}" { } ''
        mkdir $out
        for jar in ${files}/mods/*; do
          name=$(basename "$jar")
          if printf '%s\n' "$name" | grep -qiE ${lib.escapeShellArg (lib.concatStringsSep "|" serverExclude)}; then
            echo "Leaving out $name"
          else
            ln -s "$jar" "$out/$name"
          fi
        done
        ${lib.concatMapStrings (pattern: ''
          if ! ls ${files}/mods | grep -qiE ${lib.escapeShellArg pattern}; then
            echo "serverExclude: no jar in the ATM10 pack matches '${pattern}'; update packs.nix" >&2
            exit 1
          fi
        '') serverExclude}
      '';
    in
    {
      label = "ATM10";
      description = "All the Mods 10 · ${release.version} · NeoForge ${release.minecraft}";
      icon = "mdi-hammer-wrench";
      ready = release.hash != null;
      notReady =
        lib.optional (release.hash == null)
          "set release.hash in modules/homelab/minecraft/packs.nix (nix store prefetch-file --json '${release.url}' | jq -r .hash)";
      inherit (release) version;
      inherit files serverMods;

      package = p: p.neoforgeServers."neoforge-${escape release.minecraft}-${escape release.neoforge}";
    };
}
