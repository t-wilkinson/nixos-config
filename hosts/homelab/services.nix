{
  config,
  pkgs,
  lib,
  ...
}:
let
  # ==========================================
  # CONFIGURATION VARIABLES
  # ==========================================
  directIp = "10.1.0.2";
  domain = "homelab.lan";
  publicDomain = "treywilkinson.com";

  # Path to the ACME Wildcard Certificates
  certPath = "/var/lib/acme/treywilkinson.com/fullchain.pem";
  keyPath = "/var/lib/acme/treywilkinson.com/key.pem";

  # Standard Caddy TLS config using our real certs
  tlsConfig = "tls ${certPath} ${keyPath}";

  # Service Definitions
  s = {
    monitor = {
      port = 61208;
      domain = "monitor.${domain}";
      public = "monitor.${publicDomain}";
    };
    ntfy = {
      port = 8083;
      domain = "ntfy.${domain}";
      public = "ntfy.${publicDomain}";
    };
    vault = {
      port = 8000;
      domain = "vault.${domain}";
      public = "vault.${publicDomain}";
    };
    dashboard = {
      port = 8082;
      domain = "home.${domain}";
      public = "home.${publicDomain}";
    };
    nextcloud = {
      port = 8081;
      domain = "cloud.${domain}";
      public = "cloud.${publicDomain}";
    };
  };
in
{
  # ==========================================
  # DNS & BLOCKY
  # ==========================================
  services.resolved.enable = false;
  services.resolved.extraConfig = "DNSStubListener=no";

  services.blocky = {
    enable = true;
    settings = {
      ports.dns = 53;
      upstreams.groups.default = [
        "https://1.1.1.1/dns-query"
        "https://8.8.8.8/dns-query"
      ];
      customDNS = {
        customTTL = "1h";
        mapping = {
          # LAN Domain
          "homelab.lan" = directIp;
          "*.homelab.lan" = directIp;

          # SPLIT DNS:
          # For local/VPN users, resolve public domains to the PRIVATE IP.
          # This ensures they use the fast direct connection (and our Caddy certs)
          # instead of going out to the internet and back through Cloudflare Tunnel.
          "treywilkinson.com" = directIp;
          "*.treywilkinson.com" = directIp;
        };
      };
      blocking = {
        blackLists = {
          ads = [ "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts" ];
        };
        clientGroupsBlock.default = [ "ads" ];
      };
    };
  };

  # ==========================================
  # CLOUDFLARE TUNNEL (Public Access)
  # ==========================================
  # NOTE: You must create the tunnel first using: `cloudflared tunnel create homelab`
  # and put the credentials JSON file in the path defined below.
  services.cloudflared = {
    enable = true;
    tunnels = {
      "homelab-tunnel" = {
        default = "http_status:404";
        credentialsFile = config.sops.secrets.cloudflared_creds.path;
        ingress = {
          # NEXTCLOUD: Publicly accessible via Tunnel
          "cloud.${publicDomain}" = {
            # Point to local Nginx port (HTTP)
            service = "http://localhost:${toString s.nextcloud.port}";
          };
          # All other traffic is denied by the 'default' 404 rule above
        };
      };
    };
  };

  # Secret for the Tunnel credentials
  sops.secrets.cloudflared_creds = {
    format = "binary"; # The JSON file is treated as binary blob
    sopsFile = ./secrets.yaml; # You must encyrpt the json file into your secrets.yaml
    owner = "cloudflared";
  };

  # ==========================================
  # CADDY (Private/Tailscale Access)
  # ==========================================
  services.caddy = {
    enable = true;
    virtualHosts = {
      # DASHBOARD
      "${s.dashboard.domain}, ${s.dashboard.public}".extraConfig = ''
        reverse_proxy localhost:${toString s.dashboard.port}
        ${tlsConfig}
      '';

      # ROOT REDIRECT
      "${domain}, ${publicDomain}".extraConfig = ''
        redir https://${s.dashboard.public}
        ${tlsConfig}
      '';

      # NTFY
      "${s.ntfy.domain}, ${s.ntfy.public}".extraConfig = ''
        reverse_proxy localhost:${toString s.ntfy.port}
        ${tlsConfig}
      '';

      # VAULTWARDEN (Private Only)
      "${s.vault.domain}, ${s.vault.public}".extraConfig = ''
        reverse_proxy localhost:${toString s.vault.port}
        ${tlsConfig}
      '';

      # MONITOR
      "${s.monitor.domain}, ${s.monitor.public}".extraConfig = ''
        reverse_proxy localhost:${toString s.monitor.port}
        ${tlsConfig}
      '';

      # NEXTCLOUD (Private Path)
      "${s.nextcloud.domain}, ${s.nextcloud.public}".extraConfig = ''
        reverse_proxy localhost:${toString s.nextcloud.port}
        ${tlsConfig}
      '';
    };
  };

  # ==========================================
  # HOMEPAGE DASHBOARD
  # ==========================================
  services.homepage-dashboard = {
    enable = true;
    listenPort = s.dashboard.port;
    allowedHosts = [ "all" ]; # Simplified for internal dashboard
    services = [
      {
        "My Services" = [
          {
            "Ntfy" = {
              href = "https://${s.ntfy.public}";
              description = "Ntfy";
            };
          }
          {
            "Vaultwarden" = {
              href = "https://${s.vault.public}";
              description = "Password Manager";
            };
          }
          {
            "Monitoring" = {
              href = "https://${s.monitor.public}";
              description = "System monitoring";
            };
          }
          {
            "Nextcloud" = {
              href = "https://${s.nextcloud.public}";
              description = "Files";
            };
          }
        ];
      }
    ];
  };

  # ==========================================
  # APPLICATIONS
  # ==========================================

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  services.vaultwarden = {
    enable = true;
    config = {
      ROCKET_PORT = s.vault.port;
      SIGNUPS_ALLOWED = false;
      DOMAIN = "https://${s.vault.public}";
    };
  };

  services.glances = {
    enable = true;
    extraArgs = [ "-w" ];
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud32;
    hostName = s.nextcloud.public;
    https = true;
    configureRedis = true;

    config = {
      adminuser = "admin";
      dbtype = "sqlite";
      adminpassFile = config.sops.secrets.nextcloud_admin_pass.path;
    };

    settings = {
      # Trust both the Local domain and Public domain
      trusted_domains = [
        s.nextcloud.domain
        s.nextcloud.public
      ];
      overwriteprotocol = "https";
      trusted_proxies = [
        "127.0.0.1"
        "::1"
      ];
    };
  };

  # Configure Nginx (used internally by Nextcloud) to listen on the local port
  services.nginx.virtualHosts."${s.nextcloud.public}" = {
    forceSSL = lib.mkForce false;
    enableACME = lib.mkForce false;
    listen = [
      {
        addr = "127.0.0.1";
        port = s.nextcloud.port;
      }
    ];
  };

  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://${s.ntfy.public}";
      listen-http = ":${toString s.ntfy.port}";
    };
  };

  # ==========================================
  # TAILSCALE
  # ==========================================
  services.tailscale = {
    enable = true;
    openFirewall = true;
    permitCertUid = "caddy";
  };
}
