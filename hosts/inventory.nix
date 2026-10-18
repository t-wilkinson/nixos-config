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
    ];

    drives = {
      pubdrive = "/mnt/storage/pubdrive";
      pi-pubdrive = "/srv/pubdrive";
      personal = "/srv/sync/personal";
      minecraft = "/var/lib/minecraft";
      actual-budget = "/var/lib/actual-budget";
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
        # syncthingId = "X6Q657S-5M3JA3P-MMWO5VX-EPHF7BB-XQI3MPS-NV2NFSA-BCPHPOV-VFCRZAG";
      };
      pi = {
        system = "aarch64-linux"; # nixosConfigurations.homelab
        ipv4 = "10.1.0.2";
        lanInterface = "end0";
        # wanInterface = "wlp1s0u1u4"; # USB Wi-Fi dongle (hosts/homelab/wifi.nix keeps it alive)
        wanInterface = "wlan0"; # USB Wi-Fi dongle (hosts/homelab/wifi.nix keeps it alive)
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
          hubKey = null;
          extraFilesystems = {
            pi = "/srv/backup"; # the backup drive
            pc = "/mnt/storage";
          };
        };
      };
      borg = {
        host = "pi";
        expose = false;
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
