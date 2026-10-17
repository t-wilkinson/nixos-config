{
  config,
  lib,
  ...
}:
let
  homelab = config.homelab;
  nodes = homelab.nodes;
  cfg = config.homelab.services.syncthing;
in
{
  config = lib.mkMerge [
    {
      # Rewrite Host to 127.0.0.1:8384 so Syncthing's host check passes behind the proxy
      # (replaces gui.insecureSkipHostcheck)
      homelab.services.syncthing.proxyConfig = ''
        header_up Host {upstream_hostport}
      '';
    }

    (lib.mkIf cfg.runsHere {
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
        guiPasswordFile = config.sops.secrets.syncthing_pass.path;

        settings = {
          # gui.insecureSkipHostcheck = true;
          gui.user = homelab.username; # password: guiPasswordFile above
          options = {
            # nattEnabled = false;
          };

          devices = {
            "nixos" = {
              id = nodes.pc.syncthingId;
              # addresses = [ "tcp://10.1.0.1:22000" ];
              # introducer = true;
            };
            "macos" = {
              id = nodes.macos.syncthingId;
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

      # GUI password from sops, applied by syncthing-init (it runs as the syncthing user, so the
      # secret is owned by that user). Re-applied on every syncthing-init run.
      sops.secrets.syncthing_pass = {
        owner = homelab.username;
        restartUnits = [ "syncthing-init.service" ];
      };
    })
  ];
}
