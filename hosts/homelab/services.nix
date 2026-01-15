# hosts/homelab/services.nix
{
  config,
  pkgs,
  lib,
  ...
}:
let
  directIp = "10.100.0.1"; # The static IP for the direct Ethernet link to your PC
  domain = "home.lab";

  # services
  s = {
    monitor = {
      port = 61208;
      domain = "monitor.${domain}";
    };
    ntfy = {
      port = 8083;
      domain = "ntfy.${domain}";
    };
    vault = {
      port = 8000;
      domain = "vault.${domain}";
    };
    dashboard = {
      port = 8082;
      domain = "dash.${domain}";
    };
    nextcloud = {
      port = 8081;
      domain = "cloud.${domain}";
    };
    sync = {
      port = 8384;
      domain = "sync.${domain}";
    };
    zortex = {
      port = 5000;
      domain = "zortex.${domain}";
    };
  };
in
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
          "home.lab" = directIp;
          "*.home.lab" = directIp;
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
    settings.PasswordAuthentication = false;
  };

  # Caddy Reverse Proxy (HTTPS / Dashboard)
  services.caddy = {
    enable = true;
    virtualHosts = {
      "${domain}".extraConfig = "redir https://${toString s.dashboard.domain}\ntls internal";
      "${s.dashboard.domain}".extraConfig = ''
        # Serve the Root CRT at /root.crt
        handle /root.crt {
          root * /var/lib/caddy/.local/share/caddy/pki/authorities/local
          file_server {
            hide root.key
          }
        }

        # Proxy everything else to Homepage
        handle {
          reverse_proxy localhost:${toString s.dashboard.port}
        }

        tls internal
      '';
      "${s.ntfy.domain}".extraConfig = "reverse_proxy localhost:${toString s.ntfy.port}\ntls internal";
      "${s.vault.domain}".extraConfig = "reverse_proxy localhost:${toString s.vault.port}\ntls internal";
      "${s.sync.domain}".extraConfig = "reverse_proxy localhost:${toString s.sync.port}\ntls internal";
      "${s.monitor.domain}".extraConfig =
        "reverse_proxy localhost:${toString s.monitor.port}\ntls internal";
      "${s.nextcloud.domain}".extraConfig =
        "reverse_proxy localhost:${toString s.nextcloud.port}\ntls internal";
      "${s.zortex.domain}".extraConfig =
        "reverse_proxy localhost:${toString s.zortex.port}\ntls internal";
    };
  };

  # Homepage Dashboard
  services.homepage-dashboard = {
    enable = true;
    listenPort = s.dashboard.port;
    allowedHosts = "${s.dashboard.domain},${domain},localhost,127.0.0.1";
    services = [
      {
        "My Services" = [
          {
            "Root Certificate" = {
              icon = "mdi-file-certificate";
              href = "https://${s.dashboard.domain}/root.crt";
              description = "Download to trust HTTPS";
            };
          }
          {
            "Ntfy" = {
              href = "https://${s.ntfy.domain}";
              description = "Ntfy";
            };
          }
          {
            "Vaultwarden" = {
              href = "https://${s.vault.domain}";
              description = "Password Manager";
            };
          }
          {
            "Monitoring" = {
              href = "https://${s.monitor.domain}";
              description = "System monitoring";
            };
          }
          {
            "Nextcloud" = {
              href = "https://${s.nextcloud.domain}";
              description = "Files";
            };
          }
          {
            "Syncthing" = {
              href = "https://${s.sync.domain}";
              description = "Syncthing";
            };
          }
          {
            "Zortex" = {
              href = "https://${s.zortex.domain}";
              description = "Zortex";
            };
          }
        ];
      }
    ];
  };

  # PASSWORD MANAGER
  services.vaultwarden = {
    enable = true;
    config = {
      ROCKET_PORT = s.vault.port;
      SIGNUPS_ALLOWED = true;
      SHOW_PASSWORD_HINT = false;
      DOMAIN = "https://${s.vault.domain}";
    };
  };

  # MONITORING
  # services.beszel = {
  #   hub = {
  #     enable = true;
  #     port = services.monitor.port;
  #     environment = {
  #       AUTO_LOGIN = "trey@home.lab";
  #     };
  #   };
  #   agent = {
  #     enable = true;
  #     environment = {
  #       SKIP_GPU = "true";
  #       # HUB_URL = "http://127.0.0.1";
  #     };
  #   };
  # };
  # https://glances.readthedocs.io/en/latest/quickstart.html
  services.glances = {
    enable = true;
    extraArgs = [ "-w" ];
  };

  # Nextcloud
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
      trusted_domains = [ s.nextcloud.domain ];
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

  # Ntfy
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://${s.ntfy.domain}";
      listen-http = ":${toString s.ntfy.port}";
      # auth-default-access = "deny-all";
    };
  };

  # Mesh network
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  # Zortex
  # services.zortex = {
  #   enable = true;
  #   port = s.zortex.port;
  #   ntfyUrl = "http://127.0.0.1:${toString s.ntfy.port}";
  #   ntfyTopic = "zortex-notify";
  #   dataDir = "/var/lib/zortex";
  # };

  # Syncthing
  # systemd.services.syncthing.serviceConfig = {
  #   StateDirectory = "syncthing";
  #   StateDirectoryMode = "0750";
  # };
  systemd.tmpfiles.rules = [
    "d /srv/sync 0755 trey users -"
    "d /srv/sync/personal 0755 trey users -"
  ];
  services.syncthing = {
    enable = true;
    user = "trey";
    configDir = "/home/trey/.config/syncthing"; # default folder for new synced files
    dataDir = "/srv/sync";

    openDefaultPorts = true; # 22000/tcp transfer, 21027/udp discovery

    guiAddress = "127.0.0.1:${toString s.sync.port}";

    settings = {
      gui.insecureSkipHostcheck = true;
      options = {
        # nattEnabled = false;
      };

      devices = {
        "nixos" = {
          id = "X6Q657S-5M3JA3P-MMWO5VX-EPHF7BB-XQI3MPS-NV2NFSA-BCPHPOV-VFCRZAG";
          # addresses = [ "tcp://10.1.0.1:22000" ];
          # introducer = true;
        };
        "macos" = {
          id = "MACOS_ID";
          introducer = true;
        };
      };

      folders = {
        "personal" = {
          id = "personal"; # remove this line?
          path = "/srv/sync/personal";
          devices = [ "nixos" ];
        };
      };
    };
  };

}
