# hosts/nixos/default.nix
{ username, ... }:
{
  imports = [
    ./home-manager
    ./configuration.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./audio.nix
    ./locale.nix
    ./gnome.nix
    ./services.nix
    ../../modules/shared.nix
    ../../modules/homelab.nix
    ../../modules/services
    ../../modules/components/virtualisation.nix
  ];

  homelab = {
    enableServices = [
      "mc-server"
    ];
  };

  users.users.${username} = {
    extraGroups = [
      "serverdata"
      "personaldata"
    ];
  };

  security.pki.certificateFiles = [
    ../homelab/homelab-root.crt
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      wg_nixos_private_key = {
        owner = "root";
      };
    };
  };
}
