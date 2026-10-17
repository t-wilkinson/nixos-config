# hosts/homelab/inventory.nix
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

    drives = {
      pubdrive = "/mnt/storage/pubdrive";
      pi-pubdrive = "/srv/pubdrive";
      personal = "/srv/sync/personal";
      minecraft = "/var/lib/minecraft";
      actual-budget = "/var/lib/actual-budget";
    };

    nodes = {
      pc = {
        ipv4 = "10.1.0.1";
        mac = "04:7c:16:e6:d1:10";
        syncthingId = "KKNEQ5H-UN3RKTW-BKSIL55-R43FWNR-4OHY5FA-DDYL6N2-R27WQ7B-IJSXPQ3";
        # syncthingId = "X6Q657S-5M3JA3P-MMWO5VX-EPHF7BB-XQI3MPS-NV2NFSA-BCPHPOV-VFCRZAG";
      };
      pi = {
        ipv4 = "10.1.0.2";
        syncthingId = "HIAD4WE-UUAOBRY-KXKOWTA-P5HAXBL-FH3NQKF-BZLSGSO-YKNVFFI-4VUZQQE";
      };
      macos = {
        # Not on the direct link; reaches the homelab over the tailnet
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
      "glances"
      "borg"
      "mealie"
      "actual-budget"
      "wakeonlan"
      # "prometheus"
      # "grafana"

      # pc
      "nextcloud"
      "immich"
      "jupyter"
      # "mc-server"
    ];

    services = {
      ntfy = {
        host = "pi";
        port = 8083;
        isPublic = true;
      };
      vault = {
        host = "pi";
        port = 8000;
        name = "Vaultwarden";
        description = "Password manager";
        isPublic = true;
      };
      dashboard = {
        host = "pi";
        port = 8082;
        subdomain = "dash";
      };
      syncthing = {
        host = "pi";
        port = 8384;
        name = "Syncthing";
        subdomain = "sync";
      };
      zortex = {
        host = "pi";
        port = 8090;
        # paths."/notes" = "127.0.0.1:8090";
      };
      mc-server = {
        host = "pc";
        port = 25565;
        subdomain = "mc";
        isPublic = true;
        expose = false;
      };
      borg = {
        host = "pi";
        expose = false;
      };
      mealie = {
        host = "pi";
        id = 20;
        port = 9925;
        isPublic = true;
      };
      actual-budget = {
        host = "pi";
        id = 21;
        port = 5006;
        subdomain = "budget";
        isPublic = true;
        description = "Personal finance manager";
      };
      wakeonlan = {
        host = "pi";
        port = 9099;
        expose = false;
      };

      # Monitor
      prometheus = {
        host = "pi";
        name = "Prometheus";
        port = 9090;
        subdomain = "metrics";
      };
      grafana = {
        host = "pi";
        port = 3000;
      };
      glances = {
        host = "pi";
        port = 61208;
      };

      # Cloud
      pastebin = {
        host = "pi";
        port = 8088;
        subdomain = "bin";
        isPublic = true;
      };
      nextcloud = {
        host = "pc";
        # id = 10;
        port = 8081;
        subdomain = "cloud";
        isPublic = true;
      };
      immich = {
        host = "pc";
        port = 2283;
        subdomain = "photos";
        isPublic = true;
      };
      jupyter = {
        # Run by hand on the PC; LAN/tailnet only (a public Jupyter is remote code execution)
        host = "pc";
        port = 8888;
      };
    };
  };
}
