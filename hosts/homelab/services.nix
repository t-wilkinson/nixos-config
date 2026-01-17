# hosts/homelab/services.nix
{
  config,
  pkgs,
  lib,
  username,
  ...
}:
let
  directIp = "10.100.0.1"; # The static IP for the direct Ethernet link to your PC
  domain = "home.lab";
  tunnelId = "c74475c0-1f73-4fae-8bf2-a03f7c8fb6c5"; # cloudflared tunnel

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
      publicDomain = "cloud.treywilkinson.com";
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
          "${s.nextcloud.publicDomain}" = {
            service = "http://localhost:${toString s.nextcloud.port}";
            originRequest = {
              # Trick Nginx into thinking the request is for the internal domain
              httpHostHeader = s.nextcloud.domain;
            };
          };
        };
      };
    };
  };

  # CADDY Reverse Proxy (HTTPS / Dashboard)
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

  # HOMEPAGE DASHBOARD
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

  # GLANCES
  # https://glances.readthedocs.io/en/latest/quickstart.html
  services.glances = {
    enable = true;
    extraArgs = [ "-w" ];
  };

  # NEXTCLOUD
  fileSystems."/var/lib/nextcloud/data/personal" = {
    device = "/srv/sync/personal";
    options = [
      "bind"
      "ro"
    ];
  };
  users.users.nextcloud.extraGroups = [ "personaldata" ];
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

  # NTFY
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://${s.ntfy.domain}";
      listen-http = ":${toString s.ntfy.port}";
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
    port = s.zortex.port;
    ntfy.url = "https://${s.ntfy.domain}";
    ntfy.topic = "zortex-notify";
    # dataDir = "/var/lib/zortex";
  };

  # SYNCTHING
  # systemd.services.syncthing.serviceConfig = {
  #   StateDirectory = "syncthing";
  #   StateDirectoryMode = "0750";
  # };
  systemd.tmpfiles.rules = [
    "d /srv/sync 0755 ${username} users -"
    "d /srv/sync/personal 0770 ${username} personaldata -"
  ];
  services.syncthing = {
    enable = true;
    user = username;
    configDir = "/home/${username}/.config/syncthing";
    dataDir = "/srv/sync"; # default folder for new synced files

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
          id = "A6IABFJ-IS7YU6H-RASNO76-KLURNQV-QRU676J-K4GXR2H-6P2733W-ORLEMQU";
          # introducer = true;
        };
      };

      folders = {
        "personal" = {
          id = "personal"; # remove this line?
          path = "/srv/sync/personal";
          devices = [ "nixos" ];
          versioning = {
            type = "simple";
            params = {
              keep = "10";
            };
          };
        };
      };
    };
  };

  # BORG backup
  services.borgbackup.jobs."homelab-backup" = {
    # Define what to backup
    paths = [
      "/var/lib/nextcloud" # Example: Nextcloud data
      "/srv/sync"
    ];

    # Exclude temporary junk
    exclude = [
      "*.pyc"
      "/home/*/.cache"
      "*/nextcloud.db-wal"
      "*/nextcloud.db-shm"
    ];

    # The location on the USB drive
    repo = "/mnt/backup/borg";

    # Encryption: 'none' is easiest for a physical drive at home,
    # but 'repokey' is safer if the drive is lost.
    encryption = {
      mode = "none";
    };

    # Compression (zstd is fast and efficient)
    compression = "auto,zstd";

    # Schedule: Run daily at 3:00 AM
    startAt = "daily";

    # Pruning: Keep a "git-log" style history
    prune.keep = {
      daily = 7;
      weekly = 4;
      monthly = 6;
    };

    # This prevents the backup from creating a messy folder if the drive isn't there.
    preHook = ''
      if ! ${pkgs.util-linux}/bin/mountpoint -q /mnt/backup; then
        echo "Backup drive not mounted. Skipping backup."
        exit 0
      fi
    '';
  };
}
