{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./configuration.nix
    # ./gnome.nix
    ./home-manager.nix
    ./packages.nix
    ../../modules/shared.nix
  ];
}
