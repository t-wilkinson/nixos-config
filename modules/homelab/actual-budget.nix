# modules/services/actual-budget.nix
{
  config,
  lib,
  ...
}:
let
  homelab = config.homelab;
  service = homelab.services.actual-budget;
in
lib.mkIf service.enable {
  # ── Container configuration ────────────────────────────────────────
  containers.actual-budget = {
    autoStart = true;
    bindMounts = {
      "/var/lib/private/actual" = {
        hostPath = homelab.drives.actual-budget;
        isReadOnly = false;
      };
    };

    config =
      { config, pkgs, ... }:
      {
        services.actual = {
          enable = true;
          settings = {
            port = service.port;
            hostname = "0.0.0.0"; # listen on all interfaces inside the container
          };
          openFirewall = true;
        };

        system.stateVersion = lib.mkDefault homelab.containerStateVersion;
      };
  };
}
