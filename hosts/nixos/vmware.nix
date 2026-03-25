{ lib, pkgs, ... }:
{
  specialisation.vmware.configuration = {
    virtualisation.vmware.guest.enable = lib.mkForce true;
    services.xserver.videoDrivers = lib.mkForce [
      "vmware"
      "modesetting"
    ];
    services.xserver.desktopManager.gnome.enable = lib.mkForce false;

    # Fix for the black screen/cursor issues in virtualized Wayland
    environment.sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
      WLR_BACKEND = "drm";
      # Ensure standard mouse behavior in the VM
      WLR_RENDERER_ALLOW_SOFTWARE = "1";
      LIBGL_ALWAYS_SOFTWARE = "1";
    };

    xdg.portal = {
      extraPortals = lib.mkForce [
        pkgs.xdg-desktop-portal-hyprland
        pkgs.xdg-desktop-portal-gtk
      ];
    };

    hardware.graphics.extraPackages = lib.mkForce [
      pkgs.mesa
      pkgs.libdrm
    ];

    # boot.initrd.availableKernelModules = lib.mkForce [
    #   "xhci_pci"
    #   "ahci"
    #   "nvme"
    #   "usbhid"
    #   "usb_storage"
    #   "sd_mod" # From hardware-config
    #   "vmw_pvscsi"
    #   "vmw_balloon"
    #   "vmw_vmci" # VMware specific
    # ];

    # Disable hardware-specific modules that might hang the VM boot
    # boot.initrd.availableKernelModules = lib.mkForce [
    #   "uhci_hcd"
    #   "ehci_pci"
    #   "ahci"
    #   "virtio_pci"
    #   "virtio_scsi"
    #   "sd_mod"
    #   "sr_mod"
    #   "vmw_pvscsi"
    # ];
    system.nixos.tags = [ "vmware" ];
  };

  # # 1. Enable virtualization and the GUI manager
  # virtualisation.libvirtd = {
  #   enable = true;
  #   qemu = {
  #     package = pkgs.qemu_kvm;
  #     ovmf.enable = true; # Required for UEFI Windows
  #     runAsRoot = true; # Often needed for raw disk access
  #     swtpm.enable = true; # Required for Windows 11 TPM
  #   };
  # };
  # programs.virt-manager.enable = true;

  # # 2. Add your user to the necessary groups
  # users.users.trey.extraGroups = [
  #   "libvirtd"
  #   "kvm"
  # ];

  # # 3. Kernel parameters for IOMMU and Performance
  # boot.kernelParams = [
  #   "intel_iommu=on" # Change to "amd_iommu=on" if using AMD
  #   "iommu=pt"
  #   "kvm.ignore_msrs=1" # Helps with Windows BSODs
  # ];

  # # 4. (Intel 5th-10th Gen ONLY) Enable GVT-g for iGPU sharing
  # # Skip this if you have AMD or 11th+ Gen Intel
  # virtualisation.kvmgt.enable = false;

  # # 5. Performance tools
  # environment.systemPackages = with pkgs; [
  #   virt-viewer
  #   spice-gtk
  #   win-virtio # Windows VirtIO drivers (vital for disk speed)
  # ];
}
