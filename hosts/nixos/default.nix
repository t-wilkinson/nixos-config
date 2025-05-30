{ ... }:
{
  imports = [
    ./home-manager
    ./configuration.nix
    ./hardware-configuration.nix
    ./audio.nix
    ./locale.nix
    ./gnome.nix
    ../../modules/shared.nix
  ];
}
