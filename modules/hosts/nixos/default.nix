{ ... }:
let
  user = "trey";
in {
  imports = [
    ./hardware-configuration.nix
    ./configuration.nix
    ./gnome.nix
    ./home-manager
    ../../shared.nix
  ];
}
