{ pkgs, ... }:
{
  imports = [
    # ./wireguard.nix
    ./packages.nix
    # ./networking.nix
    # ./databases.nix
    ./virtualisation.nix
    # ./nfs.nix
    ./fonts.nix
  ];
}
