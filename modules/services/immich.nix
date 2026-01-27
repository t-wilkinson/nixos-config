{
  config,
  username,
  lib,
  pkgs,
  ...
}:
let
  homelab = config.homelab;
  cfg = config.homelab.services.immich;
in
{
  # IMMICH Photos viewer
  containers.immich = lib.mkIf cfg.enable {
    autoStart = true;
    # Bind mount the persistent data from the host into the container
    bindMounts = {
      "/mnt/media/drive" = {
        hostPath = homelab.drives.googledrive;
        isReadOnly = false;
      };
    };
    config =
      { ... }:
      {
        users.users.immich.extraGroups = [ "personaldata" ];

        networking.firewall.allowedTCPPorts = [ cfg.port ];

        services.immich = {
          enable = true;
          port = cfg.port;
          host = "127.0.0.1";

          # Point the main internal database/upload storage here.
          # Note: This is NOT where your existing photos live; this is for Immich metadata.
          mediaLocation = "/var/lib/immich";

          # DISABLE ML to save the Pi 4 from melting
          machine-learning.enable = false;
        };
      };
  };
}
