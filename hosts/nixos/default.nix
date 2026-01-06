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
}
