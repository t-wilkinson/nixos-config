{ ... }:
{
  services.resolved.enable = false; # Disable systemd-resolved to free port 53 for Blocky
  services.resolved.extraConfig = "DNSStubListener=no";
  services.blocky = {
    enable = true;
    settings = {
      ports.dns = 53;
      # ports.http = 4000;
      upstreams.groups.default = [
        "https://1.1.1.1/dns-query" # Cloudflare
        "https://8.8.8.8/dns-query" # Google
      ];

      # Access your services via these domains
      customDNS = {
        customTTL = "1h";
        mapping = {
          # Map main domain and all subdomains to the Pi's Direct IP
          "homelab.lan" = directIp;
          "*.homelab.lan" = directIp;
        };
      };

      # Ad Blocking
      blocking = {
        # enable = true;
        blackLists = {
          ads = [ "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts" ];
        };
        clientGroupsBlock.default = [ "ads" ];
      };
    };
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true; # Explicitly allow password auth for setup
  };

  # Caddy Reverse Proxy (HTTPS / Dashboard)
  services.caddy = {
    enable = true;
    virtualHosts = {
      "${domain}".extraConfig = "redir https://dashboard.${domain}\ntls internal";
      "ntfy.${domain}".extraConfig = "reverse_proxy localhost:8083\ntls internal";
      "dashboard.${domain}".extraConfig = "reverse_proxy localhost:8082\ntls internal";
      "vault.${domain}".extraConfig = "reverse_proxy localhost:8000\ntls internal";
      "monitor.${domain}".extraConfig = "reverse_proxy localhost:19999\ntls internal";
      "nextcloud.${domain}".extraConfig = "reverse_proxy localhost:8081\ntls internal";
    };
  };

  # Homepage Dashboard
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    allowedHosts = "dashboard.homelab.lan,homelab.lan,localhost,127.0.0.1";
    services = [
      {
        "My Services" = [
          {
            "Vaultwarden" = {
              href = "https://vault.${domain}";
              description = "Password Manager";
            };
          }
          {
            "Nextcloud" = {
              href = "https://nextcloud.${domain}";
              description = "Files";
            };
          }
        ];
      }
    ];
  };

  # Vaultwarden
  services.vaultwarden = {
    enable = true;
    config = {
      ROCKET_PORT = 8000;
      SIGNUPS_ALLOWED = false;
      DOMAIN = "https://vault.${domain}";
    };
  };

  # Netdata (Lightweight real-time monitoring)
  services.netdata = {
    enable = true;
    config.global = {
      "history" = 3600; # 1 hour of history
    };
  };

  # Nextcloud
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud32;
    hostName = "nextcloud.${domain}";
    https = true;
    configureRedis = true;

    # Tell Nextcloud it's running behind Caddy (Reverse Proxy)
    config = {
      adminuser = "admin";
      dbtype = "sqlite";
      adminpassFile = config.sops.secrets.nextcloud_admin_pass.path;
    };

    settings = {
      trusted_domains = [ "nextcloud.${domain}" ];
      # Ensure Nextcloud generates HTTPS links
      overwriteprotocol = "https";
      trusted_proxies = [
        "127.0.0.1"
        "::1"
      ];
    };
  };

  # services.nginx.enable = true;
  # services.nextcloud = {
  #   settings.trusted_domains = [
  #     "nextcloud.${domain}"
  #   ];
  # };
  services.nginx.virtualHosts."nextcloud.${domain}" = {
    forceSSL = lib.mkForce false;
    enableACME = lib.mkForce false;

    listen = [
      {
        addr = "127.0.0.1";
        port = 8081;
      }
    ];
  };

  # Ntfy
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://ntfy.${domain}";
      listen-http = ":8083";
      # auth-default-access = "deny-all";
    };
  };

}
