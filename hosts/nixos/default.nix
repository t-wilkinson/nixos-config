{ ... }:
{
  imports = [
    ./home-manager
    ./configuration.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./audio.nix
    ./locale.nix
    ./gnome.nix
    ../../modules/shared.nix
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
