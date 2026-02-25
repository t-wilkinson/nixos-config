{
  config,
  lib,
  ...
}:
let
  homelab = config.homelab;
  cfg = config.homelab.services.syncthing;
in
{
  config = lib.mkIf cfg.enable {
    # SYNCTHING
    # systemd.services.syncthing.serviceConfig = {
    #   StateDirectory = "syncthing";
    #   StateDirectoryMode = "0750";
    # };
    systemd.tmpfiles.rules = [
      "d /srv/sync 0700 - - -"
      "d /srv/sync/personal 0770 - personaldata -"
    ];
    services.syncthing = {
      enable = true;
      user = homelab.username;
      configDir = "/home/${homelab.username}/.config/syncthing";
      dataDir = "/srv/sync"; # default folder for new synced files

      openDefaultPorts = true; # 22000/tcp transfer, 21027/udp discovery

      guiAddress = cfg.localEndpoint;

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
            id = "personal";
            path = "/srv/sync/personal";
            devices = [
              "nixos"
              "macos"
            ];
            ignorePerms = true;
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
  };
}
