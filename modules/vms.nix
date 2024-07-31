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
    podman = {
      enable = true;
      # dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    lxd.enable = false;
    incus.enable = false; # make sure to run `incus admin init`
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

  users.users.${username}.extraGroups = [ "docker" "podman" "libvirtd" "lxd" "incus" ];
}
