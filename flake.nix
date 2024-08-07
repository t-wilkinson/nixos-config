{
  description = "Nixos config flake";

  outputs = { self, nixpkgs, microvm, ... }@inputs:
  let
    hostname = "nixos";
    system = "x86_64-linux";
    username = "trey";
  in
  {
    inherit username hostname system;
    overlays = import ./overlays { inherit inputs; };
    nixosConfigurations = {
      my-microvm = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          microvm.nixosModules.microvm
          { 
            systemd.network = {
              netdevs."10-microvm".netdevConfig = {
                Kind = "bridge";
                Name = "microvm";
              };
              networks."10-microvm" = {
                matchConfig.Name = "microvm";
                networkConfig = {
                  DHCPServer = true;
                  IPv6SendRA = true;
                };
                addresses = [ {
                  addressConfig.Address = "10.0.0.1/24";
                } {
                  addressConfig.Address = "fd12:3456:789a::1/64";
                } ];
                ipv6Prefixes = [ {
                  ipv6PrefixConfig.Prefix = "fd12:3456:789a::/64";
                } ];
              };
            };

            # Allow inbound traffic for the DHCP server
            networking.firewall.allowedUDPPorts = [ 67 ];
            microvm.hypervisor = "cloud-hypervisor";
          }
        ];
      };
    } // import ./hosts/${hostname} { inherit self; };
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impurity.url = "github:outfoxxed/impurity.nix";
    thorium.url = "github:end-4/nix-thorium";

    hyprland.url = "github:hyprwm/Hyprland/v0.40.0";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      # inputs.nixpkgs.follows = "hyprland";
    };

    ags.url = "github:Aylur/ags";
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
      url = "github:Kirottu/anyrun";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    NixVirt = {
      url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
