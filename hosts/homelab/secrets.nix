{ ... }:
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
        homelab_password_hash = root;
        wg_homelab_private_key = root;
        cloudflared_creds = root;
        google_app_password = root;

        nextcloud_admin_pass = root;
        nextcloud_database_pass = root;
      };
  };
}
