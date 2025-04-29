{ self, agenix, config, pkgs, ... }:

let user = "trey";
in {
  imports = [
    "${self}/modules/darwin/secrets.nix"
    ../../modules/darwin/home-manager.nix
    ../../modules/shared
    agenix.darwinModules.default
  ];

  nix = {
    package = pkgs.nix;

    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [ "@admin" "${user}" ];
      substituters =
        [ "https://cache.nixos.org" "https://nix-community.cachix.org" ];
      trusted-public-keys =
        [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
    };
  };

  system.checks.verifyNixPath = false;

  system = { };
}
