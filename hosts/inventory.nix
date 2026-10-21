# hosts/inventory.nix
#
# Data describing the homelab: nodes, network, drives and the service registry.
# Imported by every machine that is part of the homelab (the Pi and the PC).
# Each machine sets homelab.thisNode; a service runs only where `host` matches it.
# Behaviour (Caddy, cloudflared, per-service config) lives in modules/homelab and hosts/*.
{ username, ... }:
{
  homelab = {
    inherit username;
    containerStateVersion = "24.11";
    gateway = "pi"; # runs Caddy, Blocky, the Cloudflare tunnel, the subnet router, NFS exports

    adminEmail = "winston.trey.wilkinson@gmail.com";
    # Admin SSH keys: the user on every node, root on the Pi (deploys), the bootstrap images
    adminKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIID64Ajd0fkDjs12IacKz28QzlyedzzaAL8V6YmjTPd/ winston.trey.wilkinson@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIID64Ajd0fkDjs12IacKz28QzlyedzzaAL8V6YmjTPd/ pc.home.lab"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIID64Ajd0fkDjs12IacKz28QzlyedzzaAL8V6YmjTPd/ nixos"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIID64Ajd0fkDjs12IacKz28QzlyedzzaAL8V6YmjTPd/ 10.1.0.1"
    ];

    # Where data lives. Each volume is on one node; its shares get their directories
    # (owner/group/mode) there, and NFS exports + automounts for the nodes listed under nfs.
    # Modules refer to shares by name: homelab.storage.shares.<name>.path / .localPath
    # (modules/homelab/storage.nix).
    storage.volumes = {
      # PC: the storage HDD (btrfs; the .snapshots subvolume is mounted in hosts/nixos/filesystem.nix)
      pc-storage = {
        node = "pc";
        uuid = "a92044b3-8a07-43d8-a676-abbac9f6e667";
        mountPoint = "/mnt/storage";
        fsType = "btrfs";
        options = [
          "subvol=@data"
          "compress=no"
          "noatime"
          "x-systemd.device-timeout=10s"
        ];
        shares = {
          # Photos (Immich external library) and documents (Nextcloud)
          pubdrive = {
            group = "storage-media";
            mode = "2770";
            recursive = true;
            nfs.pi.mountPoint = "/srv/pubdrive";
          };
          # Immich's own data: thumbnails, encoded video, database backups
          immich = {
            owner = "immich";
            group = "storage-media";
            mode = "2770";
            recursive = true;
          };
          # Raw phone dumps (adb pull, idevicebackup2)
          phones = {
            group = "storage-media";
            mode = "2770";
          };
          # Copies of other nodes' backups (borg-mirror)
          backups = {
            owner = "root";
            group = "root";
            mode = "0700";
          };
        };
      };

      # Pi: directories on its only drive (no separate mount)
      pi-srv = {
        node = "pi";
        mountPoint = "/srv";
        shares = {
          personal = {
            subpath = "sync/personal";
            group = "personaldata";
            mode = "2770";
            nfs.pc = {
              mountPoint = "/mnt/homelab/personal";
              extraOptions = [ "x-systemd.idle-timeout=10" ];
            };
          };
          # Borg repo (backup/homelab) and the PC files copied by hand (pc-archive).
          # Not recursive: borg keeps its own ownership inside.
          backup = {
            group = "personaldata";
            mode = "0770";
          };
          # PC files copied by hand (apps/homelab/copy-to-pi)
          archive = {
            subpath = "backup/pc-archive";
            mode = "0750";
          };
        };
      };
      pi-state = {
        node = "pi";
        mountPoint = "/var/lib";
        shares = {
          minecraft = {
            group = "serverdata";
            mode = "2775";
            recursive = true;
            nfs.pc = {
              mountPoint = "/var/lib/minecraft";
              extraOptions = [
                "x-systemd.idle-timeout=10"
                "rw"
                "soft"
              ];
            };
          };
          actual-budget = {
            group = "serverdata";
            mode = "2775";
            recursive = true;
          };
        };
      };
    };

    nodes = {
      pc = {
        name = "Gaming PC";
        system = "x86_64-linux"; # nixosConfigurations.x86_64-linux(-impure), hostname "nixos"
        ipv4 = "10.1.0.1";
        lanInterface = "enp4s0";
        mac = "04:7c:16:e6:d1:10"; # enp4s0
        wakeOnLan = true;
        syncthingId = "KKNEQ5H-UN3RKTW-BKSIL55-R43FWNR-4OHY5FA-DDYL6N2-R27WQ7B-IJSXPQ3";
        # Root's key for pulling the Pi's borg repo (borg-mirror.nix)
        backupKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO/U50yCVsRpRDIFJCyRxDX2NJYZkDLleyiFf7AsCKaP phone-archive@pc";
        backupKeyFile = "/home/${username}/dev/t-wilkinson/personal/secrets/keys/phone-archive/id_ed25519";
        # syncthingId = "X6Q657S-5M3JA3P-MMWO5VX-EPHF7BB-XQI3MPS-NV2NFSA-BCPHPOV-VFCRZAG";
      };
      pi = {
        system = "aarch64-linux"; # nixosConfigurations.homelab
        ipv4 = "10.1.0.2";
        lanInterface = "end0";
        # wanInterface = "wlp1s0u1u4"; # USB Wi-Fi dongle (hosts/homelab/wifi.nix keeps it alive)
        wanInterface = "wlan0"; # built-in Wi-Fi (hosts/homelab/wifi.nix keeps it alive)
        sshHost = "home.lab"; # deploy-rs target (Blocky on the LAN; tailnet via the subnet route)
        syncthingId = "HIAD4WE-UUAOBRY-KXKOWTA-P5HAXBL-FH3NQKF-BZLSGSO-YKNVFFI-4VUZQQE";
      };
      macos = {
        # Not on the direct link; reaches the homelab over the tailnet
        system = "aarch64-darwin"; # darwinConfigurations.aarch64-darwin(-impure)
        syncthingId = "A6IABFJ-IS7YU6H-RASNO76-KLURNQV-QRU676J-K4GXR2H-6P2733W-ORLEMQU";
      };
    };

    network = {
      cidr = "10.1.0.0/30";
      domain = "home.lab";
      publicDomain = "treywilkinson.com";
      cloudflareTunnelId = "39990619-972b-46ab-9812-ee8fe70d87f0"; # <id>.cfargotunnel.com - CNAME cloudflared tunnel
      containerNetwork = "192.168.100";
    };

    groups = {
      personaldata = 987; # for exposing to synced directory to services
      serverdata = 980; # for exposing server files to services
      storage-media = 981;
      zortexdata = 986;
    };

    enableServices = [
      # pi
      "pastebin"
      "ntfy"
      "vault"
      "dashboard"
      "syncthing"
      "zortex"
      # "glances" # replaced by Beszel (history, alerts, every node, GPU)
      "gatus"
      "beszel"
      "borg"
      "blocky"
      "mealie"
      "actual-budget"
      "wakeonlan"
      "auth" # Authelia: needs the authelia_* secrets (see modules/homelab/authelia.nix)
      # "prometheus"
      # "grafana"

      # pc
      "nextcloud"
      "immich"
      "jupyter"
      "borg-mirror" # Pi's borg repo -> PC
      # "mc-server"
    ];

    services = {
      actual-budget = {
        host = "pi";
        id = 21;
        port = 5006;
        subdomain = "budget";
        isPublic = true;
        name = "Actual Budget";
        description = "Envelope Budgeting";
        dashboard = {
          icon = "mdi-finance";
          extra.ping = "https://budget.home.lab";
        };
      };
      auth = {
        # Authelia login portal for services with auth = true (LAN/tailnet only, like them)
        host = "pi";
        port = 9091;
        name = "Login";
        description = "Single sign-on for private services";
        dashboard.category = null;
      };
      beszel = {
        # Metrics hub; an agent runs on every node once data.hubKey is set
        host = "pi";
        port = 8091;
        name = "Beszel";
        description = "System metrics";
        auth = true;
        dashboard = {
          category = "Compute Nodes";
          icon = "beszel";
        };
        data = {
          # The hub's public key: Beszel UI -> Add system -> copy the key (ssh-ed25519 ...)
          hubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF7egVuJEq7mJZcR71Ylch1uaIHbQeG5UBq7eYJwJhEG";
          # Drives besides / (the Pi's /srv/backup is a folder on its root drive, so / covers it)
          extraFilesystems = {
            pc = "/mnt/storage";
          };
        };
      };
      borg = {
        host = "pi";
        expose = false;
      };
      borg-mirror = {
        # Pi -> PC: the PC copies the Pi's borg repo when it's awake (modules/homelab/borg-mirror.nix)
        host = "pc";
        expose = false;
        data = {
          source = "pi";
          share = "backups";
          keepDeletedDays = 30;
        };
      };
      blocky = {
        # LAN DNS on the gateway (modules/homelab/blocky.nix). No web UI: this exposes its
        # API (/api/blocking/status, /api/lists/refresh, ...) and /metrics behind the login.
        host = "pi";
        port = 4100; # Blocky's default 4000 is NFS statd's port here (modules/homelab/nfs.nix)
        subdomain = "dns";
        name = "Blocky DNS";
        description = "Ad-blocking & Local DNS";
        auth = true;
        dashboard = {
          category = "Infrastructure";
          icon = "mdi-dns";
        };
      };
      dashboard = {
        host = "pi";
        port = 8082;
        subdomain = "dash";
        dashboard.category = null;
        auth = true;
        authBypass = [ "/root.crt" ]; # new devices fetch the CA before they trust HTTPS
      };
      gatus = {
        # Uptime checks + status page, generated from this file; alerts to ntfy
        host = "pi";
        port = 8084;
        subdomain = "status";
        name = "Gatus";
        description = "Uptime & status";
        auth = true;
        dashboard = {
          category = "Infrastructure";
          icon = "gatus";
        };
      };
      glances = {
        host = "pi";
        port = 61208;
        description = "Monitoring";
        dashboard.category = "Compute Nodes";
      };
      grafana = {
        host = "pi";
        port = 3000;
      };
      immich = {
        host = "pc";
        port = 2283;
        subdomain = "photos";
        isPublic = true;
        description = "Photos";
        dashboard.icon = "immich";
      };
      jupyter = {
        # Run by hand on the PC; LAN/tailnet only (a public Jupyter is remote code execution)
        host = "pc";
        port = 8888;
        monitor = false; # not always running, so homelab-status shouldn't alert on it
        name = "Jupyter Lab";
        auth = true; # in front of Jupyter's token
        description = "Remote Data Science";
        dashboard = {
          category = "Compute Nodes";
          icon = "jupyter";
        };
      };
      mc-server = {
        host = "pc";
        port = 25565;
        subdomain = "mc";
        isPublic = true;
        expose = false;
      };
      mealie = {
        host = "pi";
        id = 20;
        port = 9925;
        isPublic = true;
        description = "Recipe Manager";
        dashboard.icon = "mdi-silverware-fork-knife";
      };
      nextcloud = {
        host = "pc";
        # id = 10;
        port = 8081;
        subdomain = "cloud";
        isPublic = true;
        description = "Files & Sync";
        dashboard.icon = "nextcloud";
      };
      ntfy = {
        host = "pi";
        port = 8083;
        isPublic = true;
        description = "Notifications";
      };
      pastebin = {
        host = "pi";
        port = 8088;
        subdomain = "bin";
        isPublic = true;
        description = "Pastebin (microbin)";
      };
      prometheus = {
        host = "pi";
        name = "Prometheus";
        port = 9090;
        subdomain = "metrics";
      };
      syncthing = {
        host = "pi";
        port = 8384;
        name = "Syncthing";
        subdomain = "sync";
        description = "P2P File Synchronization";
        auth = true; # in front of Syncthing's own GUI password
        dashboard = {
          category = "Infrastructure";
          icon = "syncthing";
        };
      };
      vault = {
        host = "pi";
        port = 8000;
        name = "Vaultwarden";
        description = "Password Manager";
        isPublic = true;
        dashboard = {
          category = "Infrastructure";
          icon = "vaultwarden";
        };
      };
      wakeonlan = {
        host = "pi";
        port = 9099;
        expose = false;
      };
      zortex = {
        host = "pi";
        port = 8090;
        name = "Zortex Hub";
        description = "Notification & Organization Hub";
        dashboard.icon = "mdi-bell-ring"; # widget: modules/homelab/zortex.nix
        auth = true;
        authBypass = [ "/api/*" ]; # Neovim (zortex.nvim) and the dashboard widget
      };
    };
  };
}
