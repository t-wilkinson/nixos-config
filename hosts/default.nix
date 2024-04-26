{ self, ... }:
let
  inherit (self) inputs;
  inherit (inputs) nixpkgs home-manager zjstatus;

  username = "trey";
  hostname = "nixos";
  impureHostname = "nixos-impure";

  homeDir = self + /homes;
  hm = home-manager.nixosModules.home-manager;
  homes = [
    homeDir
    hm
  ];
  impurity = inputs.impurity;
in
{
  ${hostname} = nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules =
      [
        {
          # Impurity
          imports = [ impurity.nixosModules.impurity ];
          impurity.configRoot = self;
          impurity.enable = true;
        }

        (import ./overlays.nix)

        ./nixos

        {
          networking.hostName = hostname;
          _module.args = { inherit username hostname; };
        }
      ]
      ++ homes; # imports the home-manager related configurations
  };
  ${impureHostname} = self.nixosConfigurations.${hostname}.extendModules { modules = [{ impurity.enable = true; }]; };
}
