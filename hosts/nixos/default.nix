{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./hosts/CirnOS
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
