{
  lib,
  pkgs,
  config,
  username,
  ...
}:
let
  homelab = config.homelab;
  cfg = config.homelab.services.mc-server;
in
{
  config = lib.mkMerge [
    {
      homelab.services.mc-server = {
        port = lib.mkDefault 25565;
        data = {
          rconPort = lib.mkDefault 25575;
          memoryMax = lib.mkDefault "4096M";
        };
      };
    }

    (lib.mkIf cfg.runsHere {

      # RCON password for the container (borg on the Pi uses the same secret)
      sops.secrets.minecraft_rcon_pass = {
        sopsFile = ../../hosts/homelab/secrets.yaml;
      };

      containers.mc-server = {
        autoStart = true;
        privateNetwork = false;
        bindMounts = {
          "/var/lib/minecraft" = {
            hostPath = homelab.storage.shares.minecraft.localPath; # the Pi's share, over NFS
            isReadOnly = false;
          };
        }
        // homelab.lib.mkSecretMounts [ config.sops.secrets.minecraft_rcon_pass ];
        config =
          { ... }:
          let
            rconPassFile = config.sops.secrets.minecraft_rcon_pass.path;
            # declarative = false leaves server.properties stateful, so serverProperties below
            # is NOT applied. Set the RCON fields (and keep online-mode off) before each start.
            # Runs as root ("+") so it can read the secret; the file stays owned by minecraft.
            setRconPassword = pkgs.writeShellScript "minecraft-set-rcon" ''
              set -eu
              props=/var/lib/minecraft/server.properties
              [ -f "$props" ] || exit 0
              pass="$(cat ${rconPassFile})"
              tmp="$(mktemp)"
              ${pkgs.gnugrep}/bin/grep -vE '^(rcon\.password|enable-rcon|rcon\.port|online-mode)=' "$props" > "$tmp" || true
              printf 'enable-rcon=true\nrcon.port=%s\nrcon.password=%s\nonline-mode=false\n' \
                "${toString cfg.data.rconPort}" "$pass" >> "$tmp"
              cat "$tmp" > "$props"
              rm -f "$tmp"
            '';
          in
          {
            systemd.services.minecraft-server.serviceConfig.ExecStartPre = [ "+${setRconPassword}" ];

            nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "minecraft-server" ];
            environment.systemPackages = with pkgs; [
              mcrcon
              papermc
            ];
            systemd.services.minecraft-server = {
              after = [ "var-lib-minecraft.mount" ];
              requires = [ "var-lib-minecraft.mount" ];
            };
            users.users.minecraft = {
              uid = 1000;
              extraGroups = [ "serverdata" ];
            };
            users.groups.serverdata = {
              gid = homelab.groups.serverdata;
            };

            services.minecraft-server = {
              enable = true;
              eula = true;
              openFirewall = true;
              declarative = false;
              package = pkgs.papermc;
              serverProperties = {
                server-port = cfg.port;
                gamemode = "survival";
                motd = "Welcome to the Wilkinson's Homelab!";
                white-list = false;
                online-mode = false;
                allow-cheats = true;
                view-distance = 18;

                enable-rcon = true;
                # rcon.password is injected from sops by ExecStartPre above
                "rcon.port" = cfg.data.rconPort;
              };
              jvmOpts = "-Xms4096M -Xmx8192M";
            };
            systemd.services.minecraft-server.serviceConfig.Restart = "always";
          };
      };
    })
  ];
}
