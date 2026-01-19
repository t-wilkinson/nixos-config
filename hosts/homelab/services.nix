# hosts/homelab/services.nix
{
  config,
  pkgs,
  lib,
  username,
  ...
}:
let
  tunnelId = "c74475c0-1f73-4fae-8bf2-a03f7c8fb6c5"; # cloudflared tunnel
  services = config.my-lab.services;

  mkCaddyProxy = name: service: {
    name = service.domain;
    value = {
      extraConfig = ''
        reverse_proxy localhost:${toString service.port} {
          header_up X-Real-IP {http.request.remote.host}
        }
        tls internal
      '';
    };
  };

  mkHomepageEntry = name: service: {
    ${name} = {
      description = service.description;
      href = "https://${service.domain}";
    };
  };
in
{
  my-lab.services = {
    monitor = {
      port = 61208;
    };
    ntfy = {
      port = 8083;
    };
    vault = {
      port = 8000;
      name = "Vaultwarden";
      description = "Password manager";
    };
    dashboard = {
      port = 8082;
      subdomain = "dash";
    };
    sync = {
      port = 8384;
      name = "Syncthing";
    };
    zortex = {
      port = 5000;
    };
    prometheus = {
      name = "Prometheus";
      port = 9090;
      subdomain = "metrics";
    };
    grafana = {
      port = 3000;
    };
    nextcloud = {
      port = 8081;
      subdomain = "cloud";
      isPublic = true;
    };
    immich = {
      port = 2283;
      subdomain = "photos";
      isPublic = true;
    };
  };

  # CADDY Reverse Proxy (HTTPS / Dashboard)
  services.caddy = {
    enable = true;
    virtualHosts = (lib.mapAttrs' mkCaddyReverseProxy (lib.filterAttrs (n: v: v.expose) services)) // {
      "${config.my-lab.domain}".extraConfig = "redir https://${services.dashboard.domain}\ntls internal";
      "${services.dashboard.domain}".extraConfig = ''
        # Serve the Root CRT at /root.crt
        handle /root.crt {
          root * /var/lib/caddy/.local/share/caddy/pki/authorities/local
          file_server {
            hide root.key
          }
        }

        # Proxy everything else to Homepage
        handle {
          reverse_proxy localhost:${toString services.dashboard.port}
        }

        tls internal
      '';
    };
  };

  # HOMEPAGE DASHBOARD
  services.homepage-dashboard = {
    enable = true;
    listenPort = services.dashboard.port;
    # TODO: are these necessary?
    allowedHosts = "${services.dashboard.domain},${config.my-lab.domain},localhost,127.0.0.1";
    services = [
      {
        "My Services" = [
          {
            "Root Certificate" = {
              icon = "mdi-file-certificate";
              href = "https://${services.dashboard.domain}/root.crt";
              description = "Download to trust HTTPS";
            };
          }
        ]
        ++ (lib.mapAttrsToList mkHomepageEntry (lib.filterAttrs (n: v: n != "dashboard") services));
      }
    ];
  };

  # BLOCY
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
          "home.lab" = config.my-lab.vpnIP;
          "*.home.lab" = config.my-lab.vpnIP;
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

  # OPENSSH
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  # CLOUDFLARE TUNNEL
  services.cloudflared = {
    enable = true;
    tunnels = {
      "${tunnelId}" = {
        # Path to the credentials file you generated with 'cloudflared tunnel create'
        # Since you use sops, you could also point this to
        # credentialsFile = "/var/lib/cloudflared/creds.json";
        credentialsFile = config.sops.secrets."cloudflared_creds".path;
        default = "http_status:404"; # Default Rule: Hide everything else!
        ingress = {
          "${services.immich.publicDomain}" = {
            service = "http://localhost:${toString services.immich.port}";
            originRequest = {
              # Trick Nginx into thinking the request is for the internal domain
              httpHostHeader = services.immich.domain;
            };
          };
          "${services.nextcloud.publicDomain}" = {
            service = "http://localhost:${toString services.nextcloud.port}";
            originRequest = {
              # Trick Nginx into thinking the request is for the internal domain
              httpHostHeader = services.nextcloud.domain;
            };
          };
        };
      };
    };
  };

  # PASSWORD MANAGER
  services.vaultwarden = {
    enable = true;
    config = {
      ROCKET_PORT = services.vault.port;
      SIGNUPS_ALLOWED = true;
      SHOW_PASSWORD_HINT = false;
      DOMAIN = "https://${services.vault.domain}";
    };
  };

  # GLANCES
  # https://glances.readthedocs.io/en/latest/quickstart.html
  services.glances = {
    enable = true;
    extraArgs = [ "-w" ];
  };

  # NTFY
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://${services.ntfy.domain}";
      listen-http = ":${toString services.ntfy.port}";
      # auth-default-access = "deny-all";
    };
  };

  # TAILSCALE: Mesh network
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  # ZORTEX: notes, calendar, etc.
  services.zortex = {
    enable = true;
    port = services.zortex.port;
    ntfy.url = "https://${services.ntfy.domain}";
    ntfy.topic = "zortex-notify";
    # dataDir = "/var/lib/zortex";
  };

  # FAIL2BAN
  environment.etc = {
    # Nextcloud
    "fail2ban/filter.d/nextcloud.conf".text = pkgs.lib.mkDefault (
      pkgs.lib.mkAfter ''
        [Definition]
        _groupsre = (?:(?:,?\s*"\w+":(?:"[^"]+"|\w+))*)
        failregex = ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Login failed:
                    ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Trusted domain error.
        datepattern = ,?\s*"time"\s*:\s*"%%Y-%%m-%%d[T ]%%H:%%M:%%S(%%z)?"
      ''
    );

    # Vaultwarden Filter
    "fail2ban/filter.d/vaultwarden.conf".text = ''
      [Definition]
      # Matches: [INFO] (login_attempt) Failed login attempt. IP: 192.168.1.50
      failregex = .*Failed login attempt. IP: <HOST>.*
                  .*Invalid admin token. IP: <HOST>.*
    '';
  };

  services.fail2ban = {
    enable = true;
    bantime = "24h";

    ignoreIP = [
      "10.100.0.0/24"
      "192.168.1.0/24"
      "10.1.0.1"
    ];

    jails = {
      # SSH (Standard jail)
      # sshd = ''
      #   enabled = true
      #   mode = aggressive
      # '';

      # Nextcloud
      # Converted to string to avoid "backend option does not exist" error
      nextcloud = ''
        enabled = true
        backend = auto
        port = 80,443
        protocol = tcp
        filter = nextcloud
        maxretry = 3
        bantime = 86400
        findtime = 43200
      '';
      # logpath = /var/lib/nextcloud/data/nextcloud.log

      # Vaultwarden
      vaultwarden = ''
        enabled = true
        backend = systemd
        filter = vaultwarden
        maxretry = 3
        bantime = 86400
        findtime = 14400
      '';
    };
  };

  services.prometheus = {
    enable = true;
    port = services.prometheus.port;
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9100;
      };
    };
    # Scrape locally
    scrapeConfigs = [
      {
        job_name = "homelab";
        static_configs = [
          {
            targets = [ "127.0.0.1:9100" ];
          }
        ];
      }
    ];
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = services.grafana.port;
        domain = services.grafana.domain;
      };
    };
    # Automatically add Prometheus as a data source
    provision.datasources.settings.datasources = [
      {
        name = "Prometheus";
        type = "prometheus";
        access = "proxy";
        url = "http://127.0.0.1:${toString services.prometheus.port}";
      }
    ];
  };

}
