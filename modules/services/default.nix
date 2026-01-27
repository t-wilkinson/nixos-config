{ ... }:
{
  imports = [
    ./mc-server.nix
    ./nextcloud.nix
    ./immich.nix
    ./monitoring.nix
  ];

  homelab = {
    domain = "home.lab";
    vpnIP = "10.100.0.1";
    vpnNetwork = "10.100.0";
    publicDomain = "treywilkinson.com";
    containerNetwork = "192.168.100";
    containerStateVersion = "24.11";
    drives = {
      minecraft = "/var/lib/minecraft";
      googledrive = "/srv/sync/personal/drive";
      personal = "/srv/sync/personal";
    };

    groups = {
      personaldata = 987; # for exposing to synced directory to services
      serverdata = 980; # for exposing server files to services
    };

    services = {
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
      mc-server = {
        port = 25565;
        subdomain = "mc";
        isPublic = true;
        expose = false;
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
      monitor = {
        port = 61208;
      };

      # Cloud
      nextcloud = {
        id = 10;
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
  };
}
