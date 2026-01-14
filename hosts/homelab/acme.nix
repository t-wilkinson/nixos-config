{ config, pkgs, ... }:
{
  # ==========================================
  # ACME / LET'S ENCRYPT
  # ==========================================
  security.acme = {
    acceptTerms = true;
    defaults.email = "winston.trey.wilkinson@gmail.com";

    # Certificate for treywilkinson.com and *.treywilkinson.com
    certs."treywilkinson.com" = {
      domain = "treywilkinson.com";
      extraDomainNames = [ "*.treywilkinson.com" ];

      # We use the internal LEGO client's Namecheap provider
      dnsProvider = "namecheap";

      # Path to the file containing NAMECHEAP_API_USER and NAMECHEAP_API_KEY
      credentialsFile = config.sops.templates."acme-credentials".path;

      # Allow Caddy to read these certs
      group = "caddy";

      # Reload Caddy when certs change
      postRun = "systemctl reload caddy.service";
    };
  };

  # ==========================================
  # SOPS TEMPLATE FOR NAMECHEAP
  # ==========================================
  # Lego expects specific environment variable names.
  # We map your SOPS secrets to those names here.
  sops.templates."acme-credentials" = {
    content = ''
      NAMECHEAP_API_USER=${config.sops.placeholder.namecheap_user}
      NAMECHEAP_API_KEY=${config.sops.placeholder.namecheap_api_key}
    '';
    owner = "acme";
  };

  # Define where to find these in your secrets.yaml
  sops.secrets.namecheap_user = {
    sopsFile = ./secrets.yaml;
  };
  sops.secrets.namecheap_api_key = {
    sopsFile = ./secrets.yaml;
  };
}
