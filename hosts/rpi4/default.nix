{pkgs, ...}: {
  imports = [
    <nixpkgs/nixos/modules/profiles/headless.nix>
    <nixpkgs/nixos/modules/profiles/minimal.nix>
    # <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix> # initial copy of the NixOS channel so you don't need "nix-channel --update"
  ];

  # only add strictly necessary modules
  boot.initrd.includeDefaultModules = false;
  boot.initrd.kernelModules = [ "ext4" ... ];
  disabledModules =
    [ <nixpkgs/nixos/modules/profiles/all-hardware.nix>
      <nixpkgs/nixos/modules/profiles/base.nix>
    ];

  system.defaultPackages = with pkgs; [
    vi
    coreutils
    curl
    findutils
    gnused
    gnugrep
    htop
    mtr
    pstree
    pv
    rename
    rsync
    tree
    wget
    lspci
    lsof
    tree
    gpg
    zip
    unzip
  ];

  # disable useless software
  environment.defaultPackages = [];
  xdg.icons.enable  = false;
  xdg.mime.enable   = false;
  xdg.sounds.enable = false;
}
