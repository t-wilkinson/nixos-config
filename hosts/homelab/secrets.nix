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
        owner = "root";
        group = "root";
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
