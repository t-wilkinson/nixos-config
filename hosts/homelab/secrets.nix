{ ... }:
{
  # From Caddy
  security.pki.certificateFiles = [
    ./homelab-root.crt
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ ];
    gnupg.sshKeyPaths = [ ];
    age.keyFile = "/etc/ssh/age.key";

    secrets = {
      wifi_psk = {
        owner = "root";
      };
      homelab_password_hash = {
        owner = "root";
      };
      wg_homelab_private_key = {
        owner = "root";
      };
      nextcloud_admin_pass = {
        owner = "nextcloud";
        group = "nextcloud";
      };
      cloudflared_creds = {
        owner = "root";
        group = "root";
      };
      google_app_password = {
        owner = "root";
      };
    };
  };
}
