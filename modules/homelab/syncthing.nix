{
  config,
  lib,
  pkgs,
  ...
}:
let
  homelab = config.homelab;
  nodes = homelab.nodes;
  cfg = config.homelab.services.syncthing;
  st = config.services.syncthing;
in
{
  config = lib.mkIf cfg.runsHere {
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
        # gui.insecureSkipHostcheck = true;
        gui.user = homelab.username; # password: syncthing-gui-password below
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

    sops.secrets.syncthing_pass.restartUnits = [ "syncthing-gui-password.service" ];

    # Sets the GUI password from sops without putting it in the Nix store (same idea as
    # services.syncthing.guiPasswordFile in newer nixpkgs).
    # - syncthing-init PUTs the gui section on every run, which clears the password; Requires=
    #   makes systemd re-run this unit whenever syncthing-init (re)starts.
    # - Syncthing 1.29 only accepts "$2a$" as a pre-hashed password; mkpasswd emits "$2b$"
    #   (same algorithm), so the prefix is rewritten. Tested against the 1.29.5 and 2.1.3 releases.
    # After the 26.05 upgrade (Syncthing 2.x accepts "$2b$" too) this unit can be replaced by:
    #   services.syncthing.guiPasswordFile = config.sops.secrets.syncthing_pass.path;
    systemd.services.syncthing-gui-password = {
      description = "Set the Syncthing GUI password from sops";
      after = [ "syncthing-init.service" ];
      requires = [ "syncthing-init.service" ];
      wantedBy = [
        "multi-user.target"
        "syncthing-init.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        RuntimeDirectory = "syncthing-gui-password";
        RuntimeDirectoryMode = "0700";
      };
      path = [
        pkgs.curl
        pkgs.libxml2
        pkgs.mkpasswd
        pkgs.coreutils
        pkgs.gnused
      ];
      script = ''
        set -euo pipefail
        apikey() { xmllint --xpath 'string(configuration/gui/apikey)' ${st.configDir}/config.xml; }
        api="http://${st.guiAddress}"

        # The GUI restarts after syncthing-init's PUT; wait until the API answers again
        for _ in $(seq 1 60); do
          curl -sf -H "X-API-Key: $(apikey)" "$api/rest/system/ping" > /dev/null && break
          sleep 1
        done

        tr -d '\n' < ${config.sops.secrets.syncthing_pass.path} \
          | mkpasswd -m bcrypt -R 10 --stdin | tr -d '\n' | sed 's/^\$2b\$/$2a$/' \
          > "$RUNTIME_DIRECTORY/pw"
        curl -sSf -X PATCH -H "X-API-Key: $(apikey)" \
          --variable "pw@$RUNTIME_DIRECTORY/pw" --expand-json '{ "password": "{{pw}}" }' \
          "$api/rest/config/gui"
        rm -f "$RUNTIME_DIRECTORY/pw"
      '';
    };
  };
}
