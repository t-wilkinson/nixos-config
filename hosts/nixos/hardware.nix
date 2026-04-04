{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  services.xserver.videoDrivers = [ "nvidia" ];

  environment.systemPackages = with pkgs; [
    cudaPackages.cudatoolkit
    nvidia-vaapi-driver
    nvtopPackages.nvidia
  ];

  hardware.nvidia = {
    modesetting.enable = true;

    # Power management is important for offload mode
    powerManagement.enable = true;
    powerManagement.finegrained = true; # Power down GPU when not in use
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Configure PRIME Offload
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true; # Provides the 'nvidia-offload' helper
      };

      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  boot.kernelParams = [ "btusb.enable_autosuspend=n" ];
  boot = {
    binfmt.emulatedSystems = [ "aarch64-linux" ];

    # Use the systemd-boot EFI boot loader.
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
      mesa
      libdrm
      nvidia-vaapi-driver
    ];
  };
  # hardware.nvidia.modesetting.enable = true;
  hardware.i2c.enable = true; # for ags ddcutil

}
