{
  description = "Nixos config flake";

  outputs = { self, nix-darwin, nix-homebrew, homebrew-bundle, homebrew-core
    , homebrew-cask, home-manager, nixpkgs, disko, agenix, secrets }@inputs:
    let
      user = "trey";
      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      # forAllSystems = f: nixpkgs.lib.genAttrs (linuxSystems ++ darwinSystems) f;
    in {
      darwinConfigurations = nixpkgs.lib.genAttrs darwinSystems (system:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = inputs;
          modules = [
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                inherit user;
                enable = true;
                taps = {
                  "homebrew/homebrew-core" = homebrew-core;
                  "homebrew/homebrew-cask" = homebrew-cask;
                  "homebrew/homebrew-bundle" = homebrew-bundle;
                };
                mutableTaps = false;
                autoMigrate = true;
              };
            }
            ./hosts/darwin
          ];
        });
      nixosConfigurations = nixpkgs.lib.genAttrs linuxSystems (system:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = inputs;
          modules = [
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${user} = import ./modules/nixos/home-manager.nix;
              };
            }
            ./hosts/nixos
          ];
        });
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url =
        "github:nix-community/home-manager/release-24.11"; # "follows" doesn't seem to work?
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    secrets = {
      url = "git+ssh://git@github.com/dustinlyons/nix-secrets.git";
      flake = false;
    };

    # macOS
    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = { url = "github:zhaofengli-wip/nix-homebrew"; };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # hyprland.url = "github:hyprwm/Hyprland/v0.40.0";
    # hyprland-plugins = {
    #   url = "github:hyprwm/hyprland-plugins";
    #   # inputs.nixpkgs.follows = "hyprland";
    # };
    # impurity.url = "github:outfoxxed/impurity.nix";
    # thorium.url = "github:end-4/nix-thorium";

    # ags.url = "github:Aylur/ags";
    # flake-parts = {
    #   url = "github:hercules-ci/flake-parts";
    #   inputs.nixpkgs-lib.follows = "nixpkgs";
    # };
    # gross = {
    #   url = "github:fufexan/gross";
    #   inputs.nixpkgs.follows = "nixpkgs";
    #   inputs.flake-parts.follows = "flake-parts";
    # };
    # matugen = {
    #   url = "github:/InioX/Matugen";
    #   # ref = "refs/tags/matugen-v0.10.0"
    # };
    # more-waita = {
    #   url = "github:somepaulo/MoreWaita";
    #   flake = false;
    # };
    # firefox-gnome-theme = {
    #   url = "github:rafaelmardojai/firefox-gnome-theme";
    #   flake = false;
    # };
    # anyrun = {
    #   url = "github:Kirottu/anyrun";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # NixVirt = {
    #   url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # microvm = {
    #   url = "github:astro/microvm.nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # maps directory of nix files into attribute set
    # haumea = {
    #   url = "github:nix-community/haumea";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };
}
