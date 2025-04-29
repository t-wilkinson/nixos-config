{ self, ... }:
let
  inherit (self.inputs) home-manager;

  homeDir = "${self}/homes";
  hm = home-manager.nixosModules.home-manager;
in
{
  imports = [
    homeDir
    hm
  ];
}
