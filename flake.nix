{
  description = "Nixos config flake";

  outputs =
    {
      self,

      agenix,
      ags,
      anyrun,
      darwin-docker,
      disko,
      firefox-gnome-theme,
      flake-parts,
      gross,
      home-manager,
      homebrew-bundle,
      homebrew-cask,
      homebrew-core,
      hyprland,
      hyprland-plugins,
      impurity_,
      matugen,
      more-waita,
      nix-darwin,
      nix-homebrew,
      nixpkgs,
      nixpkgs-unstable,
      thorium,
    }@inputs:
    let
      username = "trey";
      linuxSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      darwinSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      # forAllSystems = f: nixpkgs.lib.genAttrs (linuxSystems ++ darwinSystems) f;
      # devShell = system: let pkgs = nixpkgs.legacyPackages.${system}; in {
      #   default = with pkgs; mkShell {
      #     nativeBuildInputs = with pkgs; [ bashInteractive git age age-plugin-yubikey ];
      #     shellHook = with pkgs; ''
      #       export EDITOR=vim
      #     '';
      #   };
      # };

      mkApp = scriptName: system: {
        type = "app";
        program = "${
          (nixpkgs.legacyPackages.${system}.writeScriptBin scriptName ''
            #!/usr/bin/env bash
            PATH=${nixpkgs.legacyPackages.${system}.git}/bin:$PATH
            echo "Running ${scriptName} for ${system}"
            exec ${self}/apps/${system}/${scriptName}
          '')
        }/bin/${scriptName}";
      };

      mkLinuxApps = system: {
        "apply" = mkApp "apply" system;
        "b" = mkApp "build-impure" system;
        "bs" = mkApp "build-switch-impure" system;
        "build" = mkApp "build" system;
        "build-impure" = mkApp "build-impure" system;
        "build-switch" = mkApp "build-switch" system;
        "build-switch-impure" = mkApp "build-switch-impure" system;
        "copy-keys" = mkApp "copy-keys" system;
        "create-keys" = mkApp "create-keys" system;
        "check-keys" = mkApp "check-keys" system;
        "install" = mkApp "install" system;
        "install-with-secrets" = mkApp "install-with-secrets" system;
      };

      mkDarwinApps = system: {
        "apply" = mkApp "apply" system;
        "b" = mkApp "build-impure" system;
        "bs" = mkApp "build-switch-impure" system;
        "build" = mkApp "build" system;
        "build-impure" = mkApp "build-impure" system;
        "build-switch" = mkApp "build-switch" system;
        "build-switch-impure" = mkApp "build-switch-impure" system;
        "copy-keys" = mkApp "copy-keys" system;
        "create-keys" = mkApp "create-keys" system;
        "check-keys" = mkApp "check-keys" system;
        "rollback" = mkApp "rollback" system;
      };

      mkDarwinConfiguration =
        system: extraModules:
        # let
        #   pkgs = import nixpkgs {
        #     inherit system;
        #     config = {
        #       allowUnfree = true;
        #       allowBroken = true;
        #       allowUnfree = true;
        #       #cudaSupport = true;
        #       #cudaCapabilities = ["8.0"];
        #       allowInsecure = false;
        #       allowUnsupportedSystem = true;
        #     };
        #   };
        # in
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit inputs username;
            hostname = "macos";
            homedir = "/Users/${username}";
            unstable = import nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
              config.allowBroken = true;
            };
            myLib = import ./lib { inherit self; };
          };
          modules = [
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
            darwin-docker.darwinModules.docker
            # ./modules/distributed-build.nix
            {
              imports = [ impurity_.nixosModules.impurity ];
              impurity.configRoot = self;
            }
            {
              nix-homebrew = {
                user = username;
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
            ./hosts/macos
          ] ++ extraModules;
        };

      allDarwinConfigurations = builtins.listToAttrs (
        builtins.concatMap (system: [
          {
            name = system;
            value = mkDarwinConfiguration system [ ];
          }
          {
            name = "${system}-impure";
            value = mkDarwinConfiguration system [ { impurity.enable = true; } ];
          }
        ]) darwinSystems
      );

      mkNixosConfiguration =
        system: extraModules:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit self inputs username;
            hostname = "nixos";
            homedir = "/home/${username}";
            unstable = import nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
              config.allowBroken = true;
            };
            myLib = import ./lib { inherit self; };
          };
          modules = [
            home-manager.nixosModules.home-manager
            # disko.nixosModules.disko
            # agenix.nixosModules.default
            {
              imports = [ impurity_.nixosModules.impurity ];
              impurity.configRoot = self;
            }
            ./hosts/nixos
          ] ++ extraModules;
        };

      allNixosConfigurations = builtins.listToAttrs (
        builtins.concatMap (system: [
          {
            name = system;
            value = mkNixosConfiguration system [ ];
          }
          {
            name = "${system}-impure";
            value = mkNixosConfiguration system [ { impurity.enable = true; } ];
          }
        ]) linuxSystems
      );

    in
    {
      # devShells = forAllSystems devShell;
      apps =
        nixpkgs.lib.genAttrs linuxSystems mkLinuxApps
        // nixpkgs.lib.genAttrs darwinSystems mkDarwinApps;

      darwinConfigurations = allDarwinConfigurations;

      nixosConfigurations = allNixosConfigurations;
    };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11"; # "follows" doesn't seem to work?
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # impurity adds custom module arg named "impurity" which gets overriden when merging @inputs in specialArgs
    impurity_.url = "github:outfoxxed/impurity.nix";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # secrets = {
    #   url = "git+ssh://git@github.com/dustinlyons/nix-secrets.git";
    #   flake = false;
    # };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # macOS
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
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
    darwin-docker.url = "github:konradmalik/darwin-docker";

    # nixos
    hyprland.url = "github:hyprwm/Hyprland/v0.40.0";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.nixpkgs.follows = "hyprland";
    };
    thorium.url = "github:end-4/nix-thorium";
    ags = {
      url = "github:Aylur/ags/v1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    gross = {
      url = "github:fufexan/gross";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    matugen = {
      url = "github:/InioX/Matugen";
      # ref = "refs/tags/matugen-v0.10.0"
    };
    more-waita = {
      url = "github:somepaulo/MoreWaita";
      flake = false;
    };
    firefox-gnome-theme = {
      url = "github:rafaelmardojai/firefox-gnome-theme";
      flake = false;
    };
    anyrun = {
      url = "github:anyrun-org/anyrun";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
