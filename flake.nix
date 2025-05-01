{
  description = "Nixos config flake";

  outputs = { self, nix-darwin, nix-homebrew, homebrew-bundle, homebrew-core
    , homebrew-cask, home-manager, nixpkgs, nixpkgs-unstable, disko, agenix, secrets }@inputs:
    let
      user = "trey";
      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      # forAllSystems = f: nixpkgs.lib.genAttrs (linuxSystems ++ darwinSystems) f;
      # devShell = system: let pkgs = nixpkgs.legacyPackages.${system}; in {
      #   default = with pkgs; mkShell {
      #     nativeBuildInputs = with pkgs; [ bashInteractive git age age-plugin-yubikey ];
      #     shellHook = with pkgs; ''
      #       export EDITOR=vim
      #     '';
      #   };
      # };
      # mkApp = scriptName: system: {
      #   type = "app";
      #   program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin scriptName ''
      #     #!/usr/bin/env bash
      #     PATH=${nixpkgs.legacyPackages.${system}.git}/bin:$PATH
      #     echo "Running ${scriptName} for ${system}"
      #     exec ${self}/apps/${system}/${scriptName}
      #   '')}/bin/${scriptName}";
      # };
      # mkLinuxApps = system: {
      #   "apply" = mkApp "apply" system;
      #   "build-switch" = mkApp "build-switch" system;
      #   "copy-keys" = mkApp "copy-keys" system;
      #   "create-keys" = mkApp "create-keys" system;
      #   "check-keys" = mkApp "check-keys" system;
      #   "install" = mkApp "install" system;
      #   "install-with-secrets" = mkApp "install-with-secrets" system;
      # };
      # mkDarwinApps = system: {
      #   "apply" = mkApp "apply" system;
      #   "build" = mkApp "build" system;
      #   "build-switch" = mkApp "build-switch" system;
      #   "copy-keys" = mkApp "copy-keys" system;
      #   "create-keys" = mkApp "create-keys" system;
      #   "check-keys" = mkApp "check-keys" system;
      #   "rollback" = mkApp "rollback" system;
      # };

      nixpkgs-unstable-overlay = system: { nixpkgs-unstable, ... }: {
        nixpkgs.overlays = [
	  final: prev: {
	    unstable = import nixpkgs-unstable {
	      inherit system;
	      config.allowUnfree = true;
	      config.allowBroken = true;
	    };
	  }
	];
      };
    in
    {
      # templates = {
      #   starter = {
      #     path = ./templates/starter;
      #     description = "Starter configuration";
      #   };
      #   starter-with-secrets = {
      #     path = ./templates/starter-with-secrets;
      #     description = "Starter configuration with secrets";
      #   };
      # };
      # devShells = forAllSystems devShell;
      # apps = nixpkgs.lib.genAttrs linuxSystems mkLinuxApps // nixpkgs.lib.genAttrs darwinSystems mkDarwinApps;

      darwinConfigurations = nixpkgs.lib.genAttrs darwinSystems (system:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = inputs // {
	    pkgs-unstable = import nixpkgs-unstable {
	      inherit system;
	      config.allowUnfree = true;
	      config.allowBroken = true;
	    };
	  };
          modules = [
	    # (nixpkgs-unstable-overlay system)
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
            ./modules/hosts/darwin
          ];
        });
      # nixosConfigurations = nixpkgs.lib.genAttrs linuxSystems (system:
      #   nixpkgs.lib.nixosSystem {
      #     inherit system;
      #     specialArgs = inputs;
      #     modules = [
      #       disko.nixosModules.disko
      #       home-manager.nixosModules.home-manager
      #       {
      #         home-manager = {
      #           useGlobalPkgs = true;
      #           useUserPackages = true;
      #           users.${user} = import ./modules/nixos/home-manager.nix;
      #         };
      #       }
      #       ./modules/hosts/nixos
      #     ];
      #   });
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
