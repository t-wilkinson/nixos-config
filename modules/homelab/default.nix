# modules/homelab/default.nix
{ username, ... }:
let
  pcIP = "10.1.0.1";
  piIP = "10.1.0.2";
  cidr = "10.1.0.0/30";
in
{
  imports = [
    ./module.nix

    ./mc-server.nix
    ./monitoring.nix
    ./borg.nix
    ./syncthing.nix
    ./mealie.nix
    ./actual-budget.nix

    ./nextcloud.nix
    ./immich.nix
    ./pastebin.nix
  ];

  homelab = {
    inherit username;
    containerStateVersion = "24.11";

    drives = {
      minecraft = "/var/lib/minecraft";
      pubdrive = "/mnt/storage/pubdrive";
      personal = "/srv/sync/personal";
      misc = "/srv/misc";
      actual-budget = "/var/lib/actual-budget";
    };

    nodes = {
      pc = {
        ipv4 = pcIP;
        mac = "04:7c:16:e6:d1:10";
      };
      pi = {
        ipv4 = piIP;
      };
    };

    network = {
      cidr = cidr;
      domain = "home.lab";
      publicDomain = "treywilkinson.com";
      containerNetwork = "192.168.100";
    };

    groups = {
      personaldata = 987; # for exposing to synced directory to services
      serverdata = 980; # for exposing server files to services
      storage-media = 981;
    };

    services = {
      ntfy = {
        port = 8083;
      };
      vault = {
        port = 8000;
        name = "Vaultwarden";
        description = "Password manager";
        isPublic = true;
      };
      dashboard = {
        port = 8082;
        subdomain = "dash";
      };
      syncthing = {
        port = 8384;
        name = "Syncthing";
        subdomain = "sync";
      };
      zortex = {
        port = 5000;
      };
      mc-server = {
        port = 25565;
        subdomain = "mc";
        isPublic = true;
        expose = false;
      };
      borg = {
      };
      mealie = {
        id = 20;
        port = 9925;
        isPublic = true;
      };
      actual-budget = {
        id = 21;
        port = 5006;
        subdomain = "budget";
        isPublic = true;
        description = "Personal finance manager";
      };

      # Monitor
      prometheus = {
        name = "Prometheus";
        port = 9090;
        subdomain = "metrics";
      };
      grafana = {
        port = 3000;
      };
      glances = {
        port = 61208;
      };

      # Cloud
      wastebin = {
        port = 8088;
        subdomain = "bin";
        isPublic = true;
      };

      nextcloud = {
        # id = 10;
        port = 8081;
        subdomain = "cloud";
        isPublic = true;
        reverseProxy = pcIP;
      };
      immich = {
        port = 2283;
        subdomain = "photos";
        isPublic = true;
        reverseProxy = pcIP;
      };
      jupyter = {
        port = 8888;
        isPublic = true;
        reverseProxy = pcIP;
      };
    };
  };
}
