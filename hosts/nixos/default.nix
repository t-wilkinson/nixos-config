{ ... }:
{
  imports = [
    ./home-manager

    ./hardware-configuration.nix
    ./audio.nix
    ./locale.nix
    ./gnome.nix
    ./configuration.nix
    ./packages.nix
    ../../modules/shared.nix
  ];
}
