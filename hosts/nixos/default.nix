{ ... }:
{
  imports = [
    ./home-manager
    ./configuration.nix
    ./hardware-configuration.nix
    ./audio.nix
    ./locale.nix
    ./gnome.nix
    ./packages.nix
    ../../modules/shared.nix
  ];
}
