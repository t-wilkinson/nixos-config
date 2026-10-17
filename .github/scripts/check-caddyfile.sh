#!/usr/bin/env bash
# Render the homelab's generated Caddyfile and validate it with `caddy adapt`.
# Runs on x86_64: it reads the Caddyfile text out of the derivation instead of building the
# aarch64 "Caddyfile-formatted" step. This would have caught the duplicate-site outage.
set -euo pipefail

flake="${1:-.}"
drv=$(nix eval --raw "$flake#nixosConfigurations.homelab.config.services.caddy.configFile" \
  --apply 'f: builtins.head (builtins.attrNames (builtins.getContext f))')

caddyfile=$(mktemp --suffix .Caddyfile)
nix derivation show -r "$drv" | python3 -c '
import json, sys
d = json.load(sys.stdin)
d = d.get("derivations", d)
for v in d.values():
    if v.get("name") == "Caddyfile" and "text" in v.get("env", {}):
        print(v["env"]["text"])
        break
else:
    sys.exit("Caddyfile derivation not found")
' > "$caddyfile"

echo "Sites:"
grep -E '^[a-z0-9*][^ ]*\.[a-z]+.*\{\s*$' "$caddyfile" | sed 's/ *{$//' || true
# CADDY=/path/to/caddy to use a local binary instead of building the pinned one
if [ -n "${CADDY:-}" ]; then
  "$CADDY" adapt --adapter caddyfile --config "$caddyfile" > /dev/null
else
  nix run "$flake#nixosConfigurations.homelab.pkgs.buildPackages.caddy" -- \
    adapt --adapter caddyfile --config "$caddyfile" > /dev/null
fi
echo "Caddyfile OK"
