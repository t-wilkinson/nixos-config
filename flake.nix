{
  description = "Nixos config flake";

  outputs =
    {
      self,

      agenix,
      ags,
      anyrun,
      darwin-docker,
      deploy-rs,
      disko,
      firefox-gnome-theme,
      flake-parts,
      flake-utils,
      gross,
      home-manager,
      homebrew-bundle,
      homebrew-cask,
      homebrew-core,
      hyprland,
      hyprland-plugins,
      impurity-nix,
      matugen,
      more-waita,
      nix-darwin,
      nix-homebrew,
      nixos-hardware,
      nixpkgs-darwin,
      nixpkgs-nixos,
      nixpkgs-unstable,
      sops-nix,
      thorium,
      zortex,
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
      mkApps = import ./lib/mk-apps.nix { inherit self inputs; };

      mkImpureConfigurations =
        mkConfiguration: systems:
        builtins.listToAttrs (
          builtins.concatMap (system: [
            {
              name = system;
              value = mkConfiguration system [
                {
                  # Is this necessary?
                  imports = [ impurity-nix.nixosModules.impurity ];
                  impurity.configRoot = self;
                }
              ];
            }
            {
              name = "${system}-impure";
              value = mkConfiguration system [
                {
                  impurity.enable = true;
                  imports = [ impurity-nix.nixosModules.impurity ];
                  impurity.configRoot = self;
                }
              ];
            }
          ]) systems
        );

      mkDarwinConfiguration =
        system: extraModules:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit inputs username;
            hostname = "macos";
            homedir = "/Users/${username}";
            # nixpkgs-unstable branch is not built for aarch64-darwin
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
            sops-nix.darwinModules.sops

            # ./modules/distributed-build.nix
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
          ]
          ++ extraModules;
        };

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
            sops-nix.nixosModules.sops
            ./hosts/nixos
          ]
          ++ extraModules;
        };

      homelab = nixpkgs-nixos.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = {
          inherit inputs username;
          hostname = "pi";
        };
        modules = [
          "${nixpkgs-nixos}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          nixos-hardware.nixosModules.raspberry-pi-4
          zortex.nixosModules.default
          ./modules/homelab.nix
          (
            { pkgs, lib, ... }:
            {
              # The generic image asks for 'sun4i-drm', but the RPi4 kernel doesn't have it.
              # This overlay tells the build to skip missing modules instead of failing.
              nixpkgs.overlays = [
                (final: prev: {
                  makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; });
                })
              ];
            }
          )

          ({
            sdImage.compressImage = false;
            sdImage.imageName = "homelab-rpi4.img";
          })
          sops-nix.nixosModules.sops
          ./hosts/homelab
        ];
      };

    in
    {
      apps =
        nixpkgs-nixos.lib.genAttrs linuxSystems mkApps.linux
        // nixpkgs-darwin.lib.genAttrs darwinSystems mkApps.darwin;

      darwinConfigurations = mkImpureConfigurations mkDarwinConfiguration darwinSystems;

      nixosConfigurations = mkImpureConfigurations mkNixosConfiguration linuxSystems // {
        homelab = homelab;
      };

      images.homelab = homelab.config.system.build.sdImage;
      deploy.nodes.homelab = {
        hostname = "10.100.0.1";
        profiles.system = {
          user = "root";
          sshUser = "trey";
          path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.homelab;
        };
      };

      checks = builtins.mapAttrs (_: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
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

    # Utilities
    flake-utils.url = "github:numtide/flake-utils";
    sops-nix.url = "github:Mic92/sops-nix";
    # use "impurity-nix" to avoid overwritting (mergine @inputs in specialArgs) module that impurity injects named "impurity"
    impurity-nix.url = "github:outfoxxed/impurity.nix";
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
    # maps directory of nix files into attribute set
    # haumea = {
    #   url = "github:nix-community/haumea";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

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

    # homelab
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs-nixos";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # zortex
    zortex.url = "github:t-wilkinson/zortex.nvim";

    # Virtualization
    # NixVirt = {
    #   url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # microvm = {
    #   url = "github:astro/microvm.nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };
}
