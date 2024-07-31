{ pkgs, ... }: {
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
    virt-manager
    qemu
    OVMF
  ];
}
