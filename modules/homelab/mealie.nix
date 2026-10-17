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
  containers.mealie = lib.mkIf cfg.runsHere {
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
            # Links in emails/shares should work off-LAN too
            BASE_URL = "https://${if cfg.isPublic then cfg.publicDomain else cfg.domain}";
          };
        };
      };
  };
}
