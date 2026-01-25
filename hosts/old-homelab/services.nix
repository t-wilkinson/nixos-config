# ============================================================================
# services.nix - Container services and system services
# ============================================================================
{
  config,
  lib,
  pkgs,
  ...
}:

let
  dataDir = "/data";
  containerDataDir = "${dataDir}/containers";
in
{
  # Create necessary directories
  system.activationScripts.containers = ''
    mkdir -p ${containerDataDir}/{nextcloud,vaultwarden,caddy,homepage}
    mkdir -p ${dataDir}/backups
    chown -R 1000:1000 ${containerDataDir}
  '';

  # Podman containers via systemd
  # We'll use podman-compose but defined as systemd services for better integration

  virtualisation.oci-containers = {
    backend = "podman";

    containers = {
      # Caddy - Reverse proxy with automatic HTTPS and internal CA
      caddy = {
        image = "caddy:2-alpine";
        ports = [
          "80:80"
          "443:443"
          "443:443/udp"
          "8080:8080" # Admin API for CA cert download
        ];
        volumes = [
          "${containerDataDir}/caddy/data:/data"
          "${containerDataDir}/caddy/config:/config"
          "./caddy/Caddyfile:/etc/caddy/Caddyfile:ro"
        ];
        extraOptions = [
          "--network=host"
        ];
      };

      # Wake-on-LAN API server
      wol-server = {
        image = "node:18-alpine";
        ports = [ "3001:3001" ];
        volumes = [
          "./homepage/wol-server.js:/app/server.js:ro"
        ];
        environment = {
          NODE_ENV = "production";
        };
        cmd = [
          "node"
          "/app/server.js"
        ];
        extraOptions = [
          "--network=homelab"
        ];
      };

      # Nextcloud
      nextcloud = {
        image = "nextcloud:stable";
        environment = {
          POSTGRES_HOST = "nextcloud-db";
          POSTGRES_DB = "nextcloud";
          POSTGRES_USER = "nextcloud";
          POSTGRES_PASSWORD = "nextcloud_db_password"; # Use agenix in production
          NEXTCLOUD_ADMIN_USER = "admin";
          NEXTCLOUD_ADMIN_PASSWORD = "admin_password"; # Use agenix in production
          NEXTCLOUD_TRUSTED_DOMAINS = "nextcloud.homelab.local 10.0.1.1";
          OVERWRITEPROTOCOL = "https";
        };
        volumes = [
          "${containerDataDir}/nextcloud:/var/www/html"
        ];
        dependsOn = [ "nextcloud-db" ];
        extraOptions = [
          "--network=homelab"
        ];
      };

      # Nextcloud PostgreSQL
      nextcloud-db = {
        image = "postgres:15-alpine";
        environment = {
          POSTGRES_DB = "nextcloud";
          POSTGRES_USER = "nextcloud";
          POSTGRES_PASSWORD = "nextcloud_db_password";
        };
        volumes = [
          "${containerDataDir}/nextcloud/db:/var/lib/postgresql/data"
        ];
        extraOptions = [
          "--network=homelab"
        ];
      };

      # Vaultwarden
      vaultwarden = {
        image = "vaultwarden/server:latest";
        environment = {
          DOMAIN = "https://vault.homelab.local";
          SIGNUPS_ALLOWED = "true"; # Set to false after first signup
          ADMIN_TOKEN = "admin_token_here"; # Use agenix in production
        };
        volumes = [
          "${containerDataDir}/vaultwarden:/data"
        ];
        extraOptions = [
          "--network=homelab"
        ];
      };

      # Homepage Dashboard
      homepage = {
        image = "ghcr.io/gethomepage/homepage:latest";
        ports = [ "3000:3000" ];
        volumes = [
          "./homepage:/app/config"
          "/var/run/podman/podman.sock:/var/run/docker.sock:ro"
        ];
        environment = {
          PUID = "1000";
          PGID = "1000";
        };
        extraOptions = [
          "--network=homelab"
        ];
      };
    };
  };

  # Create podman network
  systemd.services.init-homelab-network = {
    description = "Create homelab podman network";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.podman}/bin/podman network exists homelab || ${pkgs.podman}/bin/podman network create homelab";
    };
  };

  # dnsmasq for local DNS
  services.dnsmasq = {
    enable = true;
    settings = {
      # Listen on WireGuard and local interfaces
      interface = [
        "wg0"
        "lo"
      ];

      # Local domain resolution
      address = [
        "/homelab.local/10.0.1.1"
        "/nextcloud.homelab.local/10.0.1.1"
        "/vault.homelab.local/10.0.1.1"
        "/home.homelab.local/10.0.1.1"
      ];

      # Upstream DNS
      server = [
        "1.1.1.1"
        "8.8.8.8"
      ];

      # Cache settings
      cache-size = 1000;
      no-negcache = true;
    };
  };

  # Backup script to desktop NFS
  systemd.services.backup-to-desktop = {
    description = "Backup data to desktop NFS";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "backup-to-desktop" ''
        #!/bin/sh
        if ${pkgs.inetutils}/bin/ping -c 1 10.0.0.2 &> /dev/null; then
          ${pkgs.rsync}/bin/rsync -avz --delete \
            ${dataDir}/ \
            10.0.0.2:/nfs/homelab-backup/
        else
          echo "Desktop not reachable, skipping backup"
        fi
      '';
    };
  };

  systemd.timers.backup-to-desktop = {
    description = "Daily backup to desktop";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  # Script to serve Caddy CA cert
  systemd.services.caddy-ca-server = {
    description = "Serve Caddy CA certificate";
    after = [ "podman-caddy.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = pkgs.writeShellScript "serve-ca" ''
        #!/bin/sh
        cd ${containerDataDir}/caddy/data/caddy/pki/authorities/local
        ${pkgs.python3}/bin/python -m http.server 8888
      '';
      Restart = "always";
    };
  };
}
