{ self, ... }:
let
  inherit (self) inputs outputs;
  inherit (inputs) nixpkgs nixpkgs-unstable impurity; # NixVirt agenix microvm;
  nixpkgs-unstable-overlay = (final: prev: {
    unstable = import nixpkgs-unstable {
      inherit (final) system;
      config.allowUnfree = true;
      config.allowBroken = true;
    };
  });
in nixpkgs.lib.nixosSystem {
  specialArgs = { inherit inputs outputs; };
  modules = [
    (import "${self}/modules/impure.nix" { inherit impurity self; })
    { nixpkgs.overlays = [ nixpkgs-unstable-overlay ]; }

    ./hardware-configuration.nix
    ./configuration.nix
    "${self}/modules/development.nix"
    "${self}/modules/hosts/gnome.nix"

    # NixVirt.nixosModules.default
    "${self}/modules/virtualisation.nix"

    # agenix.nixosModules.default
    # "${self}/modules/vpn.nix"

    # microvm.nixosModules.host
    # "${self}/modules/dev-microvm.nix"

    (import "${self}/modules/hosts/home-manager.nix" { inherit self; })
  ];
}
