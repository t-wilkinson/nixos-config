# modules/homelab/ntfy.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  homelab = config.homelab;
  services = homelab.services;
  cfg = services.ntfy;
in
{
  config = lib.mkIf cfg.runsHere {
    # NTFY
    # Private instance: nothing is readable or writable without auth. One provisioned admin user
    # (homelab.username) with one access token, ntfy_auth (tk_ + 29 chars, from `ntfy token generate`).
    # Clients send `Authorization: Bearer <token>`; the web UI/apps log in as <username> with the
    # token as the password.
    services.ntfy-sh = {
      enable = true;
      # Declarative users/tokens (auth-users / auth-tokens) need ntfy >= 2.14; 26.05 ships 2.26.
      # package = unstable.ntfy-sh;
      settings = {
        base-url = "https://${services.ntfy.domain}";
        listen-http = "127.0.0.1:${toString services.ntfy.port}"; # only Caddy and local clients
        behind-proxy = true;
        auth-default-access = "deny-all";
      };
    };

    # NTFY_AUTH_USERS needs a bcrypt hash, which a sops template can't compute, so build the
    # env file at boot. EnvironmentFile is read by systemd as root, so it can stay root-only.
    systemd.services.ntfy-sh-auth = {
      description = "Render ntfy declarative auth from sops";
      before = [ "ntfy-sh.service" ];
      requiredBy = [ "ntfy-sh.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        RuntimeDirectory = "ntfy-sh-auth";
        RuntimeDirectoryMode = "0700";
        RuntimeDirectoryPreserve = true;
        UMask = "0077";
      };
      path = [
        pkgs.mkpasswd
        pkgs.coreutils
      ];
      script = ''
        set -euo pipefail
        token="$(tr -d '\n' < ${config.sops.secrets.ntfy_auth.path})"
        hash="$(printf '%s' "$token" | mkpasswd -m bcrypt -R 10 --stdin)"
        {
          printf "NTFY_AUTH_USERS='%s:%s:admin'\n" "${homelab.username}" "$hash"
          printf "NTFY_AUTH_TOKENS='%s:%s:homelab'\n" "${homelab.username}" "$token"
        } > "$RUNTIME_DIRECTORY/env"
      '';
    };
    systemd.services.ntfy-sh.serviceConfig.EnvironmentFile = "/run/ntfy-sh-auth/env";
  };
}
