{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./configuration.nix
    ./hosts
    ./homes
    ./packages.nix
    ../../modules/shared.nix
    # ./configuration.nix
    # ./gnome.nix
    # ./home-manager.nix
    # ./packages.nix
    # ../../modules/shared.nix
  ];
}
