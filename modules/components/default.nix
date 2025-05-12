{ pkgs, ... }:
{
  imports = [
    ./packages.nix
    ./networking.nix
    # ./databases.nix
    ./virtualisation.nix
    # ./nfs.nix
    ./fonts.nix
  ];
}
