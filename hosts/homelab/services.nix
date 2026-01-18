# hosts/homelab/services.nix
{
  config,
  pkgs,
  lib,
  username,
  ...
}:
let
  vpnIp = "10.100.0.1";
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
      description = "Ntfy";
      name = "Ntfy";
    };
    vault = {
      port = 8000;
      domain = "vault.${domain}";
      name = "Vaultwarden";
      description = "Password manager";
    };
    dashboard = {
      port = 8082;
      domain = "dash.${domain}";
    };
    nextcloud = {
      port = 8081;
      domain = "cloud.${domain}";
      publicDomain = "cloud.treywilkinson.com";
      name = "Nextcloud";
      description = "Files";
    };
    sync = {
      port = 8384;
      domain = "sync.${domain}";
      name = "Syncthing";
      description = "Syncthing";
    };
    zortex = {
      port = 5000;
      domain = "zortex.${domain}";
      name = "Zortex";
      description = "Zortex";
    };
    prometheus = {
      name = "Prometheus";
      port = 9090;
      domain = "metrics.${domain}";
    };
    grafana = {
      port = 3000;
      domain = "grafana.${domain}";
      name = "Grafana";
    };
    immich = {
      port = 2283;
      domain = "photos.${domain}";
      publicDomain = "photos.treywilkinson.com";
    };
  };

  mkProxy = name: {
    name = s.${name}.domain;
    value = {
      extraConfig = ''
        reverse_proxy localhost:${toString s.${name}.port} {
          header_up X-Real-IP {http.request.remote.host}
        }
        tls internal
      '';
    };
  };

  simpleHosts = builtins.listToAttrs (
    map mkProxy [
      "ntfy"
      "vault"
      "monitor"
      "nextcloud"
      "zortex"
      "sync"
      "grafana"
      "prometheus"
      "immich"
    ]
  );

  mkHomepage = name: {
    ${s.${name}.name or name} = {
      description = s.${name}.description or "";
      href = "https://${s.${name}.domain}";
    };
  };

  simpleHomepages = map mkHomepage [
    "ntfy"
    "vault"
    "monitor"
    "nextcloud"
    "sync"
    "zortex"
    "grafana"
    "prometheus"
    "immich"
  ];

in
{
  # CADDY Reverse Proxy (HTTPS / Dashboard)
  services.caddy = {
    enable = true;
    virtualHosts = simpleHosts // {
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
        ]
        ++ simpleHomepages;
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
          "home.lab" = vpnIp;
          "*.home.lab" = vpnIp;
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
          "${s.immich.publicDomain}" = {
            service = "http://localhost:${toString s.immich.port}";
            originRequest = {
              # Trick Nginx into thinking the request is for the internal domain
              httpHostHeader = s.immich.domain;
            };
          };
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
  services.postgresql.enable = true;
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
    port = s.prometheus.port;
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
        http_port = s.grafana.port;
        domain = s.grafana.domain;
      };
    };
    # Automatically add Prometheus as a data source
    provision.datasources.settings.datasources = [
      {
        name = "Prometheus";
        type = "prometheus";
        access = "proxy";
        url = "http://127.0.0.1:${toString s.prometheus.port}";
      }
    ];
  };

  # IMMICH Photos viewer
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

  # GRANT PERMISSION: Allow Immich to read your Sync folder
  users.users.immich.extraGroups = [ "personaldata" ];
}
