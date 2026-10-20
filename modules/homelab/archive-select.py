"""Pick the files for each archive set (modules/homelab/archive.nix).

Usage: archive-select.py CONFIG.json OUTDIR

For each set in CONFIG, walks its sources, keeps the files its filters allow, orders them by
date (the yyyy-mm-dd prefix of the file name when there is one, else the modification time),
and takes files from the oldest (or newest) end until the next one would pass the size limit.
Writes OUTDIR/<set>.list: NUL-separated paths relative to /, for rsync --from0 --files-from
with / as the source. Prints one summary line per set.
"""

import fnmatch
import json
import os
import re
import sys
import time

DATE_PREFIX = re.compile(r"^(\d{4})-(\d{2})-(\d{2})")
UNITS = {"": 1, "K": 1024, "M": 1024**2, "G": 1024**3, "T": 1024**4}


def parse_size(value):
    if isinstance(value, int):
        return value
    m = re.fullmatch(r"\s*(\d+(?:\.\d+)?)\s*([KMGT]?)i?B?\s*", str(value), re.IGNORECASE)
    if not m:
        raise ValueError(f"bad size: {value!r}")
    return int(float(m.group(1)) * UNITS[m.group(2).upper()])


def file_date(name, mtime):
    """yyyy-mm-dd from the name if it starts with a real date, else from mtime."""
    m = DATE_PREFIX.match(name)
    if m:
        y, mo, d = (int(g) for g in m.groups())
        if 1900 <= y <= 2100 and 1 <= mo <= 12 and 1 <= d <= 31:
            return f"{y:04d}-{mo:02d}-{d:02d}"
    return time.strftime("%Y-%m-%d", time.localtime(mtime))


def matches(path, patterns):
    return any(fnmatch.fnmatchcase(path, p) for p in patterns)


def candidates(spec):
    """(date, path, size) for every file the set's filters allow."""
    extensions = {e.lower().lstrip(".") for e in spec.get("extensions") or []}
    exclude_ext = {e.lower().lstrip(".") for e in spec.get("excludeExtensions") or []}
    include = spec.get("include") or ["*"]
    exclude = spec.get("exclude") or []

    for source in spec["sources"]:
        source = source.rstrip("/")
        base = os.path.basename(source)
        if not os.path.isdir(source):
            print(f"warning: {source} is missing, skipped", file=sys.stderr)
            continue
        for root, dirs, files in os.walk(source):
            dirs.sort()
            for name in files:
                full = os.path.join(root, name)
                # Patterns see "<source dir name>/<path inside it>", e.g. pubdrive/2019/a.jpg
                rel = base + "/" + os.path.relpath(full, source)
                ext = name.rsplit(".", 1)[-1].lower() if "." in name else ""
                if extensions and ext not in extensions:
                    continue
                if ext in exclude_ext:
                    continue
                if not matches(rel, include) or matches(rel, exclude):
                    continue
                try:
                    st = os.lstat(full)
                except OSError:
                    continue
                if not os.path.isfile(full) or os.path.islink(full):
                    continue
                yield file_date(name, st.st_mtime), full, st.st_size


def select(spec):
    limit = parse_size(spec["limit"])
    newest = spec.get("order", "oldest") == "newest"
    files = sorted(candidates(spec), key=lambda f: (f[0], f[1]), reverse=newest)

    chosen, total = [], 0
    for date, path, size in files:
        if total + size > limit:
            break  # a clean cutoff: everything on the chosen side of one date
        chosen.append((date, path, size))
        total += size
    return files, chosen, total


def main():
    config_path, outdir = sys.argv[1], sys.argv[2]
    with open(config_path) as f:
        config = json.load(f)
    os.makedirs(outdir, exist_ok=True)

    for name, spec in sorted(config["sets"].items()):
        files, chosen, total = select(spec)
        with open(os.path.join(outdir, f"{name}.list"), "w") as out:
            for _, path, _ in chosen:
                out.write(path.lstrip("/") + "\0")
        span = f"{chosen[0][0]} .. {chosen[-1][0]}" if chosen else "nothing"
        print(
            f"{name}: {len(chosen)} of {len(files)} files, "
            f"{total / 1024**3:.2f} of {parse_size(spec['limit']) / 1024**3:.2f} GiB, {span}"
        )


if __name__ == "__main__":
    main()
