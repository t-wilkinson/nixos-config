# modules/homelab/authelia.nix
# One login for the private services (auth = true in the inventory): Caddy's forward_auth asks
# Authelia before proxying (caddy.nix). The portal is auth.home.lab / auth.treywilkinson.com,
# LAN/tailnet only, like the services it protects. One session cookie per base domain, so
# logging in once covers every protected service on that domain.
#
# Secrets (hosts/homelab/secrets.yaml, `sops hosts/homelab/secrets.yaml`):
#   authelia_jwt_secret, authelia_session_secret, authelia_storage_key
#       random, e.g. `openssl rand -hex 64` each
#   authelia_password_hash
#       `nix run nixpkgs#authelia -- crypto hash generate argon2` (the $argon2id$... line)
{
  config,
  lib,
  ...
}:
let
  homelab = config.homelab;
  services = homelab.services;
  net = homelab.network;
  cfg = services.auth;
  instance = "main";
  user = config.services.authelia.instances.${instance}.user;

  protected = lib.filterAttrs (n: s: s.enable && s.expose && s.auth) services;
  namesOf = s: [ s.domain ] ++ lib.optional (s.publicDomain != null) s.publicDomain;

  # Base domains the protected services answer on, each with the portal under it
  baseDomains = [ net.domain ] ++ lib.optional (net.publicDomain != null) net.publicDomain;
  portalFor =
    base:
    if base == net.domain then
      cfg.domain
    else
      "${cfg.subdomain}.${base}";

  secret = {
    owner = user;
    restartUnits = [ "authelia-${instance}.service" ];
  };
in
{
  config = lib.mkIf cfg.runsHere {
    sops.secrets = {
      authelia_jwt_secret = secret;
      authelia_session_secret = secret;
      authelia_storage_key = secret;
      authelia_password_hash = { };
    };

    # File backend with a single user; the password hash comes from sops
    sops.templates."authelia-users.yml" = {
      owner = user;
      restartUnits = [ "authelia-${instance}.service" ];
      content = ''
        users:
          ${homelab.username}:
            displayname: "${homelab.username}"
            password: "${config.sops.placeholder.authelia_password_hash}"
            email: "${homelab.username}@${net.domain}"
            groups:
              - admins
      '';
    };

    services.authelia.instances.${instance} = {
      enable = true;
      secrets = {
        jwtSecretFile = config.sops.secrets.authelia_jwt_secret.path;
        sessionSecretFile = config.sops.secrets.authelia_session_secret.path;
        storageEncryptionKeyFile = config.sops.secrets.authelia_storage_key.path;
      };
      settings = {
        theme = "auto";
        server.address = "tcp://${cfg.localEndpoint}/";
        log.level = "info";

        authentication_backend = {
          file.path = config.sops.templates."authelia-users.yml".path;
          # The users file is read-only (rendered by sops); change the password in secrets.yaml
          password_reset.disable = true;
          password_change.disable = true;
        };

        access_control = {
          default_policy = "deny";
          rules = [
            {
              domain = lib.concatLists (lib.mapAttrsToList (n: s: namesOf s) protected);
              policy = "one_factor";
            }
          ];
        };

        session = {
          inactivity = "1w";
          expiration = "4w";
          remember_me = "3M";
          cookies = map (base: {
            domain = base;
            authelia_url = "https://${portalFor base}";
            default_redirection_url = "https://${
              if base == net.domain then services.dashboard.domain else services.dashboard.publicDomain
            }";
          }) baseDomains;
        };

        storage.local.path = "/var/lib/authelia-${instance}/db.sqlite3";

        # Only needed for identity checks (2FA registration): the code is written to this file
        notifier.filesystem.filename = "/var/lib/authelia-${instance}/notification.txt";

        regulation = {
          max_retries = 5;
          find_time = "10m";
          ban_time = "30m";
        };
      };
    };
  };
}
