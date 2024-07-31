{ outputs, pkgs, ... }: 
let
  inherit (outputs) username;
in
{
  home-manager.users.${username} = {
    home.packages = with pkgs; [
      virt-manager
      virt-viewer
      spice
      spice-gtk
      spice-protocol
      win-virtio
      win-spice
      # lxc
      # lxd-lts
      distrobuilder
      incus
      qemu
      OVMF
    ];
  };

  virtualisation = {
    docker.enable = true;
    lxd.enable = false;
    incus.enable = true; # make sure to run `incus admin init`
    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
        ovmf.enable = true;
        ovmf.packages = [ pkgs.OVMFFull.fd ];
      };
      # allowedBridges = [ "${cfg.libvert.bridgeInterface}" ];

    };
    spiceUSBRedirection.enable = true;
  };

  environment.systemPackages = with pkgs; [
  ];

  users.users.${username}.extraGroups = [ "docker" "libvirtd" "lxd" "incus" ];
}
