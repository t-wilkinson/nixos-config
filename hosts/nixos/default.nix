{ self, ... }:
let
  inherit (self) inputs outputs;
  inherit (inputs) nixpkgs NixVirt impurity agenix microvm;
  inherit (outputs) username hostname;

  impureHostname = "nixos-impure";
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

        microvm.nixosModules.host
        {
          microvm.autostart = [
            "my-microvm"
          ];
        }

        ./hardware-configuration.nix
        ./configuration.nix
        "${self}/modules/hosts/gnome.nix"

        agenix.nixosModules.default
        "${self}/modules/vpn.nix"

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
