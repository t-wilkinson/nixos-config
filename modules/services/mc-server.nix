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

    (lib.mkIf cfg.enable {

      users.users.${username} = {
        extraGroups = [ "serverdata" ];
      };
      containers.mc-server = {
        autoStart = true;
        privateNetwork = false;
        bindMounts = {
          "/var/lib/minecraft" = {
            hostPath = homelab.drives.minecraft;
            isReadOnly = false;
          };
        };
        config =
          { ... }:
          {

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

                enable-rcon = true;
                "rcon.password" = "password";
                "rcon.port" = cfg.data.rconPort;
              };
              jvmOpts = "-Xms2048M -Xmx4096M";
            };
            systemd.services.minecraft-server.serviceConfig.Restart = "always";
          };
      };
    })
  ];
}
