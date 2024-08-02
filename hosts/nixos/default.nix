{ self, ... }:
let
  inherit (self) inputs outputs;
  inherit (inputs) nixpkgs NixVirt;
  inherit (outputs) username hostname;

  impureHostname = "nixos-impure";
  impurity = inputs.impurity;
in
{
  ${hostname} = nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs outputs; };
    modules =
      [
        {
          # TODO: write an overlay for impurity?
          # Impurity
          imports = [ impurity.nixosModules.impurity ];
          impurity.configRoot = self;
          impurity.enable = true;
        }

        ./hardware-configuration.nix
        ./configuration.nix
        "${self}/modules/hosts/gnome.nix"

        {
          networking.hostName = hostname;
          _module.args = { inherit username hostname; };
        }

        (import "${self}/modules/hosts/home-manager.nix" { inherit self; })

        "${self}/modules/virtualisation.nix"
        NixVirt.nixosModules.default

        "${self}/modules/development.nix"
      ];
  };
  ${impureHostname} = self.nixosConfigurations.${hostname}.extendModules { modules = [{ impurity.enable = true; }]; };
}
