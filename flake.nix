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
      nixpkgs-nixos,
      nixpkgs-darwin,
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

      mkApp = pkgs: scriptName: system: {
        type = "app";
        program = "${
          (pkgs.writeScriptBin scriptName ''
            #!/usr/bin/env bash
            PATH=${pkgs.git}/bin:$PATH
            echo "Running ${scriptName} for ${system}"
            exec ${self}/apps/${system}/${scriptName}
          '')
        }/bin/${scriptName}";
      };

      mkLinuxApps = system: 
      let
        app = scriptName: mkApp (nixpkgs-nixos.legacyPackages.${system}) scriptName system;
      in
      {
        "apply" = app "apply";
        "b" = app "build-impure";
        "bs" = app "build-switch-impure";
        "build" = app "build";
        "build-impure" = app "build-impure";
        "build-switch" = app "build-switch";
        "build-switch-impure" = app "build-switch-impure";
        "copy-keys" = app "copy-keys";
        "create-keys" = app "create-keys";
        "check-keys" = app "check-keys";
        "install" = app "install";
        "install-with-secrets" = app "install-with-secrets";
      };

      mkDarwinApps = system: 
      let
        app = scriptName: mkApp (nixpkgs-darwin.legacyPackages.${system}) scriptName system;
      in
      {
        "apply" = app "apply";
        "b" = app "build-impure";
        "bs" = app "build-switch-impure";
        "build" = app "build";
        "build-impure" = app "build-impure";
        "build-switch" = app "build-switch";
        "build-switch-impure" = app "build-switch-impure";
        "copy-keys" = app "copy-keys";
        "create-keys" = app "create-keys";
        "check-keys" = app "check-keys";
        "rollback" = app "rollback";
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
            # nixpkgs-unstable branch is not build for aarch64-darwin
            unstable = import nixpkgs-nixos {
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
        nixpkgs-nixos.lib.nixosSystem {
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
        nixpkgs-nixos.lib.genAttrs linuxSystems mkLinuxApps
        // nixpkgs-darwin.lib.genAttrs darwinSystems mkDarwinApps;

      darwinConfigurations = allDarwinConfigurations;

      nixosConfigurations = allNixosConfigurations;
    };

  inputs = {
    # NixPkgs
    # nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-nixos.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05"; # "follows" doesn't seem to work?
      inputs.nixpkgs.follows = "nixpkgs-nixos";
    };

    # impurity adds custom module arg named "impurity" which gets overriden when merging @inputs in specialArgs
    impurity_.url = "github:outfoxxed/impurity.nix";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs-nixos";
    };
    # secrets = {
    #   url = "git+ssh://git@github.com/dustinlyons/nix-secrets.git";
    #   flake = false;
    # };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs-nixos";
    };

    # macOS
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
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
      inputs.nixpkgs.follows = "nixpkgs-nixos";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs-nixos";
    };
    gross = {
      url = "github:fufexan/gross";
      inputs.nixpkgs.follows = "nixpkgs-nixos";
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
      inputs.nixpkgs.follows = "nixpkgs-nixos";
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
