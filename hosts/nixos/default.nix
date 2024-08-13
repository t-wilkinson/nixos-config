{ self, ... }:
let
  inherit (self) inputs outputs;
  inherit (inputs) nixpkgs NixVirt impurity agenix microvm;
  inherit (outputs) username hostname;
in
nixpkgs.lib.nixosSystem {
  specialArgs = { inherit inputs outputs; };
  modules =
    [
      (import "${self}/modules/impure.nix" { inherit impurity self; })

      ./hardware-configuration.nix
      ./configuration.nix
      "${self}/modules/hosts/gnome.nix"
      "${self}/modules/development.nix"

      NixVirt.nixosModules.default
      "${self}/modules/virtualisation.nix"

      agenix.nixosModules.default
      "${self}/modules/vpn.nix"

      # microvm.nixosModules.host
      # "${self}/modules/dev-microvm.nix"

      (import "${self}/modules/hosts/home-manager.nix" { inherit self; })
    ];
}
