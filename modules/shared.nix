{ ... }:
{
  imports = [
    ./home-manager
    ./nix.nix
    ./packages.nix
    ./ssh-hosts.nix # `ssh pi`, `ssh pc` everywhere (from hosts/inventory.nix)
    # ./virtualisation.nix
    # ./fonts.nix
  ];
}
