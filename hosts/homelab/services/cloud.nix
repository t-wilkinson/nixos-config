{
  config,
  username,
  lib,
  pkgs,
  ...
}:
let
  services = config.homelab.services;
  secrets = config.sops.secrets;
in
{
  # NEXTCLOUD
  containers.nextcloud = {
    autoStart = true;
    bindMounts = {
      "/var/lib/nextcloud/data/personal" = {
        hostPath = "/srv/sync/personal";
        isReadOnly = false;
      };
    }
    // config.homelab.lib.mkSecretMounts [
      secrets.nextcloud_database_pass
      secrets.nextcloud_admin_pass
      secrets.google_app_password
    ];

    config =
      let
        hostConfig = config;
      in
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        networking.firewall.allowedTCPPorts = [ services.nextcloud.port ];
        users.users.nextcloud.extraGroups = [ "personaldata" ];

        services.postgresql = {
          enable = true;
          ensureDatabases = [ "nextcloud" ];
          enableTCPIP = false;
          ensureUsers = [
            {
              name = "nextcloud";
              ensureDBOwnership = true;
            }
          ];
        };

        services.nginx.virtualHosts."${services.nextcloud.domain}" = {
          serverAliases = [ services.nextcloud.publicDomain ];
          forceSSL = lib.mkForce false;
          enableACME = lib.mkForce false;

          listen = [
            {
              addr = "0.0.0.0";
              port = services.nextcloud.port;
            }
          ];
        };

        systemd.services.nextcloud-setup = {
          after = [ "postgresql.service" ];
          requires = [ "postgresql.service" ];
        };

        services.nextcloud = {
          enable = true;
          package = pkgs.nextcloud32;
          hostName = services.nextcloud.domain;
          https = true;
          configureRedis = true;
          database.createLocally = true;

          config = {
            adminuser = "admin";
            adminpassFile = secrets.nextcloud_admin_pass.path;

            dbtype = "pgsql";
            dbname = "nextcloud";
            dbuser = "nextcloud";
            # dbhost = "localhost";
            dbhost = "/run/postgresql";
            # dbpassFile = secrets.nextcloud_database_pass.path;
          };

          settings = {
            overwritehost = services.nextcloud.publicDomain;
            overwriteprotocol = "https";

            trusted_domains = [
              services.nextcloud.containerIP
              services.nextcloud.domain
              services.nextcloud.publicDomain
            ];
            trusted_proxies = [
              "127.0.0.1"
              hostConfig.homelab.hostContainerIP
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

        # systemd.services.nextcloud-set-smtp-pass = {
        #   description = "Set Nextcloud SMTP password from sops";
        #   after = [ "nextcloud-setup.service" ];
        #   wants = [ "nextcloud-setup.service" ];
        #   serviceConfig = {
        #     Type = "oneshot";
        #     User = "nextcloud";
        #   };
        #   script = ''
        #     ${config.services.nextcloud.occ}/bin/occ \
        #     config:system:set mail_smtppassword \
        #     --value "$(cat ${secrets.google_app_password.path})"
        #   '';
        # };
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

        networking.firewall.allowedTCPPorts = [ services.immich.port ];

        services.immich = {
          enable = true;
          port = services.immich.port;
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
