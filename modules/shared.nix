{ ... }:
{
  imports = [
    ./home-manager
    # ./services
    # ./homelab.nix
    ./components/nix.nix
    ./components/packages.nix
    # ./components/virtualisation.nix
    # ./components/fonts.nix
  ];
}
