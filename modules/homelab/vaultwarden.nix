# modules/homelab/vaultwarden.nix
# Password manager. Public (the Bitwarden apps need it away from home); the admin page is
# LAN/tailnet only.
{
  config,
  lib,
  unstable,
  ...
}:
let
  homelab = config.homelab;
  services = homelab.services;
  cfg = services.vault;
  privateRanges = homelab.lib.caddyPrivateRanges;
in
{
  config = lib.mkMerge [
    {
      homelab.services.vault.extraConfig = ''
        # Admin page: LAN/tailnet only. Internet traffic arrives through the tunnel carrying the
        # visitor's real IP ({client_ip} = Cf-Connecting-Ip), so it can't pass this.
        @adminNotLan {
          path /admin*
          not client_ip ${privateRanges}
        }
        respond @adminNotLan "Access Denied" 403
      '';
    }

    (lib.mkIf cfg.runsHere {
      sops.templates."vaultwarden-env".content = ''
        ADMIN_TOKEN=${config.sops.placeholder.vaultwarden_admin_hash}
        SMTP_PASSWORD=${config.sops.placeholder.google_app_password}
      '';

      # PASSWORD MANAGER
      services.vaultwarden = {
        enable = true;
        package = unstable.vaultwarden;
        environmentFile = config.sops.templates."vaultwarden-env".path;
        config = {
          ROCKET_PORT = services.vault.port;
          SIGNUPS_ALLOWED = false;
          INVITATIONS_ALLOWED = false;
          SHOW_PASSWORD_HINT = false;
          WEBSOCKET_ENABLED = true;
          DOMAIN = "https://${services.vault.publicDomain}";

          SMTP_HOST = "smtp.gmail.com";
          SMTP_FROM = "winston.trey.wilkinson@gmail.com";
          SMTP_PORT = 587;
          SMTP_SECURITY = "starttls";
          SMTP_USERNAME = "winston.trey.wilkinson@gmail.com";
        };
      };

      # FAIL2BAN (enabled on the gateway in fail2ban.nix): ban after repeated failed logins
      environment.etc."fail2ban/filter.d/vaultwarden.conf".text = ''
        [Definition]
        # Matches: [INFO] (login_attempt) Failed login attempt. IP: 192.168.1.50
        failregex = .*Failed login attempt. IP: <HOST>.*
                    .*Invalid admin token. IP: <HOST>.*
      '';
      services.fail2ban.jails.vaultwarden = ''
        enabled = true
        filter = vaultwarden
        maxretry = 3
        bantime = 86400
        findtime = 14400
        backend = systemd
        journalmatch = _SYSTEMD_UNIT=vaultwarden.service
      '';
    })
  ];
}
