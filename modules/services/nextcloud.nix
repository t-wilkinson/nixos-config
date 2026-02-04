{ lib, config, ... }:
let
  homelab = config.homelab;
  cfg = config.homelab.services.nextcloud;
  secrets = config.sops.secrets;
in
{
  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules =
      let
        groups = lib.mapAttrs (k: v: toString v) homelab.groups;
      in
      [
        "d /mnt/media/personal 0770 nextcloud ${groups.personaldata} - -"
        "Z /mnt/media/personal 0770 nextcloud ${groups.personaldata} - -"
        "d /mnt/media/drive 0770 nextcloud ${groups.serverdata} - -"
        "Z /mnt/media/drive 0770 nextcloud ${groups.serverdata} - -"
      ];

    containers.nextcloud = {
      autoStart = true;
      bindMounts = {
        "/mnt/media/personal" = {
          hostPath = homelab.drives.personal;
          isReadOnly = false;
        };
        "/mnt/media/drive" = {
          hostPath = homelab.drives.googledrive;
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
          networking.firewall.allowedTCPPorts = [ cfg.port ];
          users.users.nextcloud.extraGroups = [
            "personaldata"
            "serverdata"
          ];

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

          services.nginx.virtualHosts."${cfg.domain}" = {
            serverAliases = [ cfg.publicDomain ];
            forceSSL = lib.mkForce false;
            enableACME = lib.mkForce false;

            listen = [
              {
                addr = "0.0.0.0";
                port = cfg.port;
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
            hostName = cfg.domain;
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
              overwritehost = cfg.publicDomain;
              overwriteprotocol = "https";

              trusted_domains = [
                cfg.localIP
                cfg.domain
                cfg.publicDomain
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
  };
}
