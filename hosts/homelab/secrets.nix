{ config, ... }:
{
  # Caddy certificate
  security.pki.certificateFiles = [
    ./homelab-root.crt
  ];

  # Provision the SSH key generated in Phase 1
  # environment.etc."ssh/ssh_host_ed25519_key" = {
  #   source = ./ssh_host_ed25519_key;
  #   mode = "0600";
  # };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ ];
    gnupg.sshKeyPaths = [ ];
    age.keyFile = "/etc/ssh/age.key";

    secrets =
      let
        root = {
          owner = "root";
          group = "root";
        };
      in
      {
        wifi_psk = root;
        # wg_homelab_private_key = root; # WireGuard is no longer used
        cloudflared_creds = root;
        google_app_password = root;

        nextcloud_admin_pass = root;
        nextcloud_database_pass = root;
        vaultwarden_admin_hash = root;

        borg_pass = root; # borg repokey passphrase
        minecraft_rcon_pass = root; # borg talks to the Minecraft server over RCON
        # ntfy access token (tk_...). Restarting ntfy-sh-auth also restarts ntfy-sh (Requires=).
        ntfy_auth = root // {
          restartUnits = [
            "ntfy-sh-auth.service"
            "zortex-web.service"
          ];
        };

        # Login password for the user (mkpasswd -m yescrypt). neededForUsers decrypts it into
        # /run/secrets-for-users *before* users are created; without it the users script runs
        # first and the password never changes.
        homelab_password_hash.neededForUsers = true;
        # syncthing_pass: modules/homelab/syncthing.nix, microbin_pass: modules/homelab/pastebin.nix
      };

    # curl -H @file: lets scripts authenticate to ntfy without putting the token in argv
    templates."ntfy-auth-header".content = ''
      Authorization: Bearer ${config.sops.placeholder.ntfy_auth}
    '';
  };
}
