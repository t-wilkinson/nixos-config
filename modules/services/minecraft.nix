{ lib, config, ... }:
let
  homelab = config.homelab;
  service = homelab.services.minecraft;
in
{
  options = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  mc-server =
    { self, ... }:
    {
      port = service.port;
      container = {
        autoStart = true;
        privateNetwork = false;
        # forwardPorts = [
        #   {
        #     containerPort = services.mc-server.port;
        #     hostPort = services.mc-server.port;
        #     protocol = "tcp";
        #   }
        # ];

        bindMounts = {
          # Bind mount data to host for easy Borg backups
          "/var/lib/minecraft" = {
            hostPath = "/var/lib/minecraft";
            isReadOnly = false;
          };
        };

        config =
          { ... }:
          let
            rconPort = 25575;
          in
          {
            networking.firewall.allowedTCPPorts = [
              services.mc-server.port
              rconPort
            ];
            nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "minecraft-server" ];
            environment.systemPackages = [ pkgs.mcrcon ];
            users.groups.serverdata.gid = 980;
            services.minecraft-server = {
              enable = true;
              eula = true;
              openFirewall = true;
              declarative = false;
              serverProperties = {
                server-port = services.mc-server.port;
                gamemode = "survival";
                motd = "Welcome to the Wilkinson's Homelab!";
                white-list = false;
                online-mode = false;
                allow-cheats = true;

                enable-rcon = true;
                "rcon.password" = "password";
                "rcon.port" = rconPort;
              };
              jvmOpts = "-Xms2048M -Xmx4096M";
            };
            systemd.services.minecraft-server.serviceConfig.Restart = "always";
          };
      };
    };
}
