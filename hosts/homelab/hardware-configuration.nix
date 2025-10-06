# ============================================================================
# hardware-configuration.nix - Hardware-specific configuration
# ============================================================================
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Raspberry Pi 4 specific
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "usbhid"
    "usb_storage"
  ];

  # File systems
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [
      "noatime"
      "nodiratime"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/FIRMWARE";
    fsType = "vfat";
  };

  # Data partition for Nextcloud
  fileSystems."/data" = {
    device = "/dev/disk/by-label/DATA";
    fsType = "ext4";
    options = [
      "noatime"
      "nodiratime"
    ];
  };

  # Swap
  swapDevices = [
    {
      device = "/swapfile";
      size = 2048; # 2GB
    }
  ];

  # Enable hardware support
  hardware.enableRedistributableFirmware = true;
  hardware.raspberry-pi."4".apply-overlays-dtmerge.enable = true;

  nixpkgs.hostPlatform = "aarch64-linux";
}
