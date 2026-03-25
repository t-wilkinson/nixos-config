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
      "/mnt/media/pubdrive" = {
        hostPath = homelab.drives.pubdrive;
        isReadOnly = false;
      };
    };
    config =
      { ... }:
      {
        systemd.tmpfiles.rules =
          let
            groups = lib.mapAttrs (k: v: toString v) homelab.groups;
          in
          [
            "d /mnt/media/pubdrive 0770 immich ${groups.serverdata} - -"
            "Z /mnt/media/pubdrive 0770 immich ${groups.serverdata} - -"
          ];

        users.users.immich = {
          uid = 1000;
          isSystemUser = true;
          group = "immich";
          extraGroups = [
            "serverdata"
          ];
        };
        users.groups.immich.gid = 1000;
        users.groups.personaldata = {
          gid = homelab.groups.personaldata;
        };

        networking.firewall.allowedTCPPorts = [ cfg.port ];

        services.immich = {
          enable = true;
          user = "immich";
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
