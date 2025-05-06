{ ... }:
{
  imports = [
    ./components
    ./home-manager
  ];

  nix.settings = {
    substituters = [
      "https://nix-community.cachix.org"
      "https://cache.nixos.org/"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      #cudaSupport = true;
      #cudaCapabilities = ["8.0"];
      allowBroken = true;
      allowInsecure = false;
      allowUnsupportedSystem = true;
    };

    # overlays = let
    #   node18 = pkgs.nodejs_18;
    # in [
    #   (self: super: {
    #     # nodePackages = prev.nodePackages.override { nodejs = node18; };
    #     # mynpm = prev.nodePackages.npm.overrideAttrs (oldAttrs: {
    #     #   buildInputs = oldAttrs.buildInputs ++ [ node18 ];
    #     #   propagatedBuildInputs = (oldAttrs.propagatedBuildInputs or []) ++ [ node18 ];
    #     # });
    #     mypkgs = {
    #       npm = super.nodePackages.npm.overrideAttrs (oldAttrs: {
    #           buildInputs = oldAttrs.buildInputs ++ [ node18 ];
    #           propagatedBuildInputs = (oldAttrs.propagatedBuildInputs or []) ++ [ node18 ];
    #           # After installation, rewrite the shebang to use node18
    #           postInstall = ''
    #             substituteInPlace $out/bin/npm \
    #               --replace "#!.*node" "#!${node18}/bin/node"
    #           '';
    #         });
    #     };
    #   })
    # ];

    # overlays = let
    # emacsOverlaySha256 = "06413w510jmld20i4lik9b36cfafm501864yq8k4vxl5r4hn0j0h";
    # Apply each overlay found in the /overlays directory
    # let path = ../../overlays; in with builtins;
    # map (n: import (path + ("/" + n)))
    #     (filter (n: match ".*\\.nix" n != null ||
    #                 pathExists (path + ("/" + n + "/default.nix")))
    #             (attrNames (readDir path)))
    # ++ [(import (builtins.fetchTarball {
    #          url = "https://github.com/dustinlyons/emacs-overlay/archive/refs/heads/master.tar.gz";
    #          sha256 = emacsOverlaySha256;
    #      }))];
  };
}
