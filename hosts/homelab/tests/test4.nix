      # let
      #   system = "aarch64-linux";
      # in
      # nixpkgs-nixos.lib.nixosSystem {
      #   inherit system;
      #   modules = [
      #     agenix.nixosModules.default
      #     (
      #       { pkgs, ... }:
      #       {
      #         imports = [
      #           ./hosts/rpi4
      #           (nixpkgs-nixos + "/nixos/modules/installer/cd-dvd/sd-image-aarch64.nix")
      #         ];

      #         # Build an sdImage with multiple partitions
      #         boot.loader.grub.enable = false;
      #         boot.loader.generic-extlinux-compatible.enable = true;

      #         sdImage = {
      #           compressImage = false;
      #           populateFirmwareCommands = ''
      #             mkdir -p ./files/boot
      #           '';
      #           populateRootCommands = ''
      #             mkdir -p ./files/root
      #           '';
      #           # Define custom partitions
      #           partitions = {
      #             boot = {
      #               size = "256M";
      #               fsType = "vfat";
      #               mountPoint = "/boot";
      #             };
      #             root = {
      #               size = "20G";
      #               fsType = "ext4";
      #               mountPoint = "/";
      #             };
      #             data = {
      #               size = "100%"; # take remaining space
      #               fsType = "ext4";
      #               mountPoint = "/data";
      #             };
      #           };
      #         };
      #       }
      #     )
      #   ];
      # };


