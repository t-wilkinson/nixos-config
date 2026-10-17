# modules/sops-check.nix
#
# Fail at evaluation time when a declared sops secret is missing from its YAML file.
# Without this, a missing key only shows up at activation, where sops-install-secrets aborts
# and *every* secret on the machine goes missing (Caddy, cloudflared, Vaultwarden, ...).
# Key names are stored in plaintext by sops, so this needs no decryption.
{ config, lib, ... }:
let
  topLevelKeys =
    file:
    lib.pipe (builtins.readFile file) [
      (lib.splitString "\n")
      (map (builtins.match "([A-Za-z0-9_.-]+):.*"))
      (lib.filter (m: m != null))
      (map builtins.head)
    ];

  # /nix/store/<hash>-source/hosts/x/secrets.yaml -> hosts/x/secrets.yaml
  repoPath =
    file:
    let
      m = builtins.match "/nix/store/[^/]+/(.*)" (toString file);
    in
    if m == null then toString file else builtins.head m;

  check =
    name: s:
    let
      checkable = s.format == "yaml" && !(lib.hasInfix "/" s.key) && s.key != "";
    in
    {
      assertion = !checkable || lib.elem s.key (topLevelKeys s.sopsFile);
      message = ''sops secret "${name}": key "${s.key}" is missing from ${repoPath s.sopsFile}; add it with `sops ${repoPath s.sopsFile}` before deploying (a missing key makes activation fail for every secret).'';
    };
in
{
  assertions = lib.mapAttrsToList check config.sops.secrets;
}
