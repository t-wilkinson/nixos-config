{ outputs, pkgs, ... }: 
let
  inherit (outputs) username;
in
{
  home-manager.users.${username} = {
    home.packages = with pkgs; [
      virt-manager
      virt-viewer
      libguestfs

      # lxc
      # lxd-lts
      # distrobuilder
      # incus
      qemu
      OVMF

      spice
      spice-gtk
      spice-protocol
      win-virtio
      win-spice
    ];
  };

  boot.kernelModules = [ "kvm-intel" ];
  virtualisation = {
    docker.enable = true;
    podman = {
      enable = true;
      # dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    lxd.enable = false;
    incus.enable = false; # make sure to run `incus admin init`
    libvirtd = {
      enable = true;
      onBoot = "ignore";
      onShutdown = "shutdown";
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
        ovmf.enable = true;
        ovmf.packages = [ pkgs.OVMFFull.fd ];
      };
      # allowedBridges = [ "${cfg.libvert.bridgeInterface}" ];
    };
    spiceUSBRedirection.enable = true;
  };

  networking.firewall.trustedInterfaces = [ "virbr0" ];
  networking.bridges.virbr0.interfaces = [];

  environment.systemPackages = with pkgs; [
  ];

  users.users.${username}.extraGroups = [ "docker" "podman" "libvirtd" "lxd" "incus" "kvm" ];
}
