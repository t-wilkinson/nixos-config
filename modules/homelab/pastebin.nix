{ config, lib, ... }:
let
  cfg = config.homelab.services.pastebin;
in
lib.mkIf cfg.runsHere {
  # Admin login and uploader password (MICROBIN_ADMIN_PASSWORD / MICROBIN_UPLOADER_PASSWORD).
  # Admin credentials come from sops instead of the built-in defaults.
  sops.secrets.microbin_pass = { };
  sops.templates."microbin-env".restartUnits = [ "microbin.service" ];
  sops.templates."microbin-env".content = ''
    MICROBIN_ADMIN_USERNAME=${config.homelab.username}
    MICROBIN_ADMIN_PASSWORD=${config.sops.placeholder.microbin_pass}
    MICROBIN_UPLOADER_PASSWORD=${config.sops.placeholder.microbin_pass}
  '';

  # microbin has easily shareable links
  services.microbin = {
    enable = true;
    passwordFile = config.sops.templates."microbin-env".path;
    settings = {
      MICROBIN_PORT = cfg.port;
      MICROBIN_BIND = "127.0.0.1"; # only Caddy talks to it
      # MICROBIN_ENABLE_PASTA_LIST isn't a microbin option; the /pastalist page is on unless NO_LISTING is set
      MICROBIN_NO_LISTING = true;
      MICROBIN_ENCRYPTION_CLIENT_SIDE = true;
      MICROBIN_MAX_FILE_SIZE_UNENCRYPTED_MB = 500;
      MICROBIN_PUBLIC_PATH = "https://${cfg.publicDomain}/";
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
