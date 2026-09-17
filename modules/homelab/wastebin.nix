{ config, ... }:
let
  cfg = config.homelab.services.wastebin;
in
{
  services.microbin = {
    enable = true;
    settings = {
      MICROBIN_PORT = cfg.port;
      MICROBIN_BIND = "0.0.0.0";
      # Enables the /pastalist directory on the web UI
      MICROBIN_ENABLE_PASTA_LIST = true;
      MICROBIN_ENCRYPTION_CLIENT_SIDE = true;
    };
  };
  # services.wastebin = {
  #   enable = true;
  #   settings = {
  #     WASTEBIN_PORT = cfg.port;

  #     WASTEBIN_ADDRESS_PORT = "0.0.0.0:${toString cfg.port}";
  #     # WASTEBIN_TITLE_PAGE = "Homelab Paste";
  #   };
  # };
}
