{ ... }:
{
  imports = [
    ./mc-server.nix
  ];

  homelab = {
    drives = {
      minecraft = "/var/lib/minecraft";
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
