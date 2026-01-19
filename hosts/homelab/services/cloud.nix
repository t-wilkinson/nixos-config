{
  config,
  username,
  lib,
  ...
}:
let
  s = config.my-lab.services;
  secrets = config.sops.secrets;
in
{
  # NEXTCLOUD
  containers.nextcloud = {
    bindMounts = {
      "/var/lib/nextcloud/data/personal" = {
        hostPath = "/srv/sync/personal";
        isReadOnly = false;
      };
      ${config.sops.secrets.nextcloud_admin_pass.path} = {
        hostPath = config.sops.secrets.nextcloud_admin_pass.path;
        isReadOnly = true;
      };
      ${config.sops.secrets.google_app_password.path} = {
        hostPath = config.sops.secrets.google_app_password.path;
        isReadOnly = true;
      };
    };

    config = {
      networking.firewall.allowedTCPPorts = [ s.nextcloud.port ];

      users.users.nextcloud.extraGroups = [ "personaldata" ];
      services.postgresql.enable = false;
      services.nextcloud = {
        enable = true;
        package = pkgs.nextcloud32;
        hostName = s.nextcloud.domain;
        https = true;
        configureRedis = true;

        # Tell Nextcloud it's running behind Caddy (Reverse Proxy)
        config = {
          adminuser = "admin";
          dbtype = "sqlite";
          adminpassFile = config.sops.secrets.nextcloud_admin_pass.path;
        };

        settings = {
          overwritehost = s.nextcloud.publicDomain;
          trusted_domains = [
            s.nextcloud.domain
            s.nextcloud.publicDomain
          ];
          # Ensure Nextcloud generates HTTPS links
          overwriteprotocol = "https";
          trusted_proxies = [
            "127.0.0.1"
            "::1"
          ];

          # mail_smtpmode = "smtp";
          # mail_sendmailmode = "smtp";

          # # The email people see when they receive notifications
          # mail_from_address = "admin";
          # mail_domain = "treywilkinson.com"; # Combined -> admin@treywilkinson.com

          # # SMTP Connection Settings (Example: Gmail)
          # # For Gmail: Use "smtp.gmail.com", Port 465, and SSL.
          # mail_smtphost = "smtp.gmail.com";
          # mail_smtpport = 465;
          # mail_smtpsecure = "ssl"; # "ssl" for port 465, "tls" for port 587
          # mail_smtpauth = true;
          # mail_smtpname = "winston.trey.wilkinson@gmail.com";
          # # NOTE: putting the password here means it will be readable in /nix/store
          # # mail_smtppassword = "your-app-password";
          # add:
          # SPF record
          # DKIM record
          # Often DMARC (strongly recommended)
        };

        extraAppsEnable = true;
        # extraApps = {
        #   inherit (config.services.nextcloud.package.packages.apps) external;
        # };
      };

      systemd.services.nextcloud-set-smtp-pass = {
        description = "Set Nextcloud SMTP password from sops";
        after = [ "nextcloud-setup.service" ];
        wants = [ "nextcloud-setup.service" ];
        serviceConfig = {
          Type = "oneshot";
          User = "nextcloud";
        };
        script = ''
          ${config.services.nextcloud.occ}/bin/occ \
          config:system:set mail_smtppassword \
          --value "$(cat ${config.sops.secrets.google_app_password.path})"
        '';
      };

      services.nginx.virtualHosts."${s.nextcloud.domain}" = {
        forceSSL = lib.mkForce false;
        enableACME = lib.mkForce false;

        listen = [
          {
            addr = "127.0.0.1";
            port = s.nextcloud.port;
          }
        ];
      };
    };
  };

  # IMMICH Photos viewer
  containers.immich = {
    autoStart = true;
    # Bind mount the persistent data from the host into the container
    bindMounts = {
      "/mnt/media/drive" = {
        hostPath = "/srv/sync/personal/drive";
        isReadOnly = false;
      };
    };
    config =
      { ... }:
      {
        users.users.immich.extraGroups = [ "personaldata" ];
        networking.firewall.allowedTCPPorts = [ s.immich.port ];

        services.immich = {
          enable = true;
          port = s.immich.port;
          host = "127.0.0.1";

          # Point the main internal database/upload storage here.
          # Note: This is NOT where your existing photos live; this is for Immich metadata.
          mediaLocation = "/var/lib/immich";

          # DISABLE ML to save the Pi 4 from melting
          machine-learning.enable = false;
        };
      };
  };
}
