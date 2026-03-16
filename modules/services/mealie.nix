{
  config,
  lib,
  ...
}:
let
  cfg = config.homelab.services.mealie;
in
{
  # MEALIE Recipe Manager
  containers.mealie = lib.mkIf cfg.enable {
    autoStart = true;
    config =
      { ... }:
      {
        networking.firewall.allowedTCPPorts = [ cfg.port ];

        services.mealie = {
          enable = true;
          port = cfg.port;
          listenAddress = "0.0.0.0";

          database.createLocally = true;

          settings = {
            BASE_URL = "https://${cfg.domain}";
          };
        };
      };
  };
}
