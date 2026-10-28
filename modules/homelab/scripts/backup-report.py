"""Backup status for the dashboard (modules/homelab/backup-report.nix).

Combines two sources into backups.json:
  - each borg repo on this node: newest archive, its size, the repo's size, archive count.
    Read by backup-report-<repo>.service as the repo's own user (borg-pc's repo must not get
    root-owned files), which leaves `borg info` / `borg list` JSON in its runtime directory.
  - Gatus: the last result of every job that reports there (./jobs.nix), including the PC's.

  backup-report --config CONFIG.json
"""

import argparse
import grp
import json
import os
import re
import sys
import time
import urllib.request
from datetime import datetime, timezone


def parse_time(value):
    """Timestamp from borg (local time, no offset) or Gatus (RFC 3339, nanoseconds)."""
    if not value:
        return None
    value = value.replace("Z", "+00:00")
    # Python takes at most 6 fractional digits
    value = re.sub(r"(\.\d{6})\d+", r"\1", value)
    dt = datetime.fromisoformat(value)
    if dt.tzinfo is None:
        dt = dt.astimezone()  # borg writes local time
    return dt.timestamp()


def iso(ts):
    return datetime.fromtimestamp(ts, timezone.utc).isoformat() if ts else None


def span(seconds):
    s = max(0, seconds)
    if s < 3600:
        return f"{int(s // 60)}m"
    if s < 2 * 86400:
        return f"{int(s // 3600)}h"
    return f"{int(s // 86400)}d"


def ago(ts, now):
    if ts is None:
        return "never"
    if now - ts < 60:
        return "just now"
    return f"{span(now - ts)} ago"


def read_json(path):
    try:
        with open(path) as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def repo_status(repo, previous, now):
    d = repo["dir"]
    info = read_json(os.path.join(d, "info.json"))
    listing = read_json(os.path.join(d, "list.json"))
    try:
        with open(os.path.join(d, "error")) as f:
            error = f.read().strip() or "borg failed"
    except OSError:
        error = None
    out = {"name": repo["name"], "path": repo["path"], "error": error}

    if info and info.get("archives"):
        a = info["archives"][0]
        stats = a.get("stats", {})
        cache = info.get("cache", {}).get("stats", {})
        out.update({
            "archive": a.get("name"),
            "last": iso(parse_time(a.get("end") or a.get("start"))),
            "duration": a.get("duration"),
            "added": stats.get("deduplicated_size"),
            "original": stats.get("original_size"),
            "files": stats.get("nfiles"),
            "size": cache.get("unique_csize"),
            "archives": len(listing.get("archives", [])) if listing else None,
            "checkedAt": iso(os.path.getmtime(os.path.join(d, "info.json"))),
        })
    elif previous:
        # Nothing read this boot (or this run): keep the last known numbers
        for k in ("archive", "last", "duration", "added", "original", "files",
                  "size", "archives", "checkedAt"):
            out[k] = previous.get(k)
    elif not error:
        out["error"] = "no archives yet"

    last = parse_time(out.get("last"))
    age = (now - last) / 3600 if last else None
    out["ageHours"] = round(age, 1) if age is not None else None
    if out["error"] and not last:
        out["status"] = "error"
        out["statusText"] = f"error: {out['error'].splitlines()[-1][:80]}"
    elif age is None or age > repo["maxAgeHours"]:
        out["status"] = "stale"
        out["statusText"] = f"stale · last {ago(last, now)}"
    elif out["error"]:
        out["status"] = "warning"
        out["statusText"] = f"ok · {ago(last, now)} (repo unreadable now)"
    else:
        out["status"] = "ok"
        out["statusText"] = f"ok · {ago(last, now)}"
    return out


def gatus_results(url):
    """{key: [results, oldest first]} for every endpoint in Gatus."""
    with urllib.request.urlopen(
            f"{url}/api/v1/endpoints/statuses?page=1&pageSize=100",
            timeout=15) as resp:
        statuses = json.load(resp)
    out = {}
    for s in statuses:
        results = s.get("results") or []
        results.sort(key=lambda r: parse_time(r.get("timestamp")) or 0)
        out[s.get("key")] = results
    return out


def job_status(job, results, now):
    out = {"name": job["name"], "node": job["node"], "heartbeat": job["heartbeat"]}
    if results is None:
        out.update(ok=None, last=None, error="Gatus unavailable",
                   failures7d=None, summary="unknown (Gatus unavailable)")
        return out
    if not results:
        out.update(ok=None, last=None, error=None, failures7d=0,
                   summary="no report yet")
        return out
    r = results[-1]
    ts = parse_time(r.get("timestamp"))
    errors = r.get("errors") or []
    failures = sum(1 for x in results
                   if not x.get("success")
                   and (parse_time(x.get("timestamp")) or 0) > now - 7 * 86400)
    out.update(ok=bool(r.get("success")), last=iso(ts),
               error="; ".join(errors) or None, failures7d=failures)
    if r.get("success"):
        out["summary"] = f"ok · {ago(ts, now)}"
    elif any(e.startswith("heartbeat") for e in errors):
        last_run = parse_time(job_last_run(results))
        out["summary"] = (f"no run for {span(now - last_run)}" if last_run
                          else "never ran")
    else:
        out["summary"] = f"FAILED · {ago(ts, now)}"
    return out


def job_last_run(results):
    """Timestamp of the newest result that came from the job itself."""
    for r in reversed(results):
        if not any(e.startswith("heartbeat") for e in r.get("errors") or []):
            return r.get("timestamp")
    return None


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--config", required=True)
    args = p.parse_args()
    with open(args.config) as f:
        cfg = json.load(f)
    now = time.time()
    previous = read_json(cfg["out"]) or {}

    repos = {r["id"]: repo_status(r, previous.get("repos", {}).get(r["id"]), now)
             for r in cfg["repos"]}

    jobs = {}
    if cfg.get("jobs"):
        try:
            results = gatus_results(cfg["gatus"]) if cfg.get("gatus") else None
        except OSError as e:
            print(f"Gatus: {e}", file=sys.stderr)
            results = None
        for job in cfg["jobs"]:
            jobs[job["id"]] = job_status(
                job, None if results is None else results.get(job["key"], []), now)

    problems = [f"{r['name']} backup {r['status']}" for r in repos.values()
                if r["status"] not in ("ok", "warning")]
    problems += [f"{j['name']} failed" for j in jobs.values() if j["ok"] is False]
    report = {
        "generated": iso(now),
        "summary": {
            "status": "attention" if problems else "ok",
            "text": "; ".join(problems) or "all backups ok",
        },
        "repos": repos,
        "jobs": jobs,
    }

    tmp = cfg["out"] + ".tmp"
    with open(tmp, "w") as f:
        json.dump(report, f, indent=1)
        f.write("\n")
    os.chmod(tmp, 0o640)
    if cfg.get("group"):
        os.chown(tmp, -1, grp.getgrnam(cfg["group"]).gr_gid)
    os.replace(tmp, cfg["out"])
    print(report["summary"]["text"])


if __name__ == "__main__":
    main()
