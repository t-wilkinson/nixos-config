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
          # Only Caddy talks to it: on 0.0.0.0, a tailnet client could skip Caddy and set its
          # own X-Real-IP
          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_PORT = services.vault.port;
          # The client address for logs and rate limits: Caddy sets it to {client_ip}, the real
          # visitor for tunnel traffic (Cf-Connecting-Ip from cloudflared only, caddy.nix)
          IP_HEADER = "X-Real-IP";
          # At most 5 login attempts in a burst, then one a minute (per address; counts 2FA too)
          LOGIN_RATELIMIT_SECONDS = 60;
          LOGIN_RATELIMIT_MAX_BURST = 5;
          PASSWORD_HINTS_ALLOWED = false;
          SIGNUPS_ALLOWED = false;
          INVITATIONS_ALLOWED = true;
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

      # FAIL2BAN (on the gateway, fail2ban.nix). Vaultwarden logs each failed login with the
      # client's address (IP_HEADER, which Caddy sets to the real visitor) and the account:
      #   Username or password is incorrect. Try again. IP: 1.2.3.4. Username: a@b.c.
      # Bans apply in Caddy and at Cloudflare (homelab.bans.action), not iptables: tunnel
      # traffic arrives from 127.0.0.1. Both jails notify, naming the accounts tried.
      homelab.bans = {
        jails = [
          "vaultwarden"
          "vaultwarden-2fa"
        ];
        journalUnits = [ "vaultwarden.service" ];
      };
      environment.etc."fail2ban/filter.d/vaultwarden.conf".text = ''
        [Definition]
        # Wrong master password (or login-with-device code, or API key), unknown account, admin
        # token. (Strings from vaultwarden's src/api/identity.rs and src/api/admin.rs.)
        failregex = ^.*Username or (?:password|access code) is incorrect\. Try again\. IP: <ADDR>\. Username: .*$
                    ^.*Incorrect client_secret\. IP: <ADDR>\. Username: .*$
                    ^.*Invalid admin token\. IP: <ADDR>$
                    ^.*Invalid or expired admin JWT\. IP: <ADDR>\.$
      '';
      # A wrong 2FA code comes after a correct master password: someone may have your password
      environment.etc."fail2ban/filter.d/vaultwarden-2fa.conf".text = ''
        [Definition]
        failregex = ^.*Invalid TOTP code! Server time: .* IP: <ADDR>$
      '';
      services.fail2ban.jails = {
        # Three wrong passwords in 12 hours: banned for a day (longer for repeat offenders,
        # bantime.increment in fail2ban.nix). Vaultwarden's own rate limit (LOGIN_RATELIMIT_*
        # above) slows guessing down meanwhile.
        vaultwarden.settings = {
          filter = "vaultwarden";
          backend = "systemd";
          journalmatch = "_SYSTEMD_UNIT=vaultwarden.service";
          maxretry = 3;
          findtime = "12h";
          bantime = "1d";
          action = config.homelab.bans.action;
        };
        # One typo allowed; the second wrong code bans for a week
        vaultwarden-2fa.settings = {
          filter = "vaultwarden-2fa";
          backend = "systemd";
          journalmatch = "_SYSTEMD_UNIT=vaultwarden.service";
          maxretry = 2;
          findtime = "1d";
          bantime = "1w";
          action = config.homelab.bans.action;
        };
      };
    })
  ];
}
