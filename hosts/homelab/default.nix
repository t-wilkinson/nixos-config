# hosts/homelab/default.nix
{
  config,
  pkgs,
  username,
  lib,
  ...
}:
{
  homelab.enableServices = [
    "ntfy"
    "vault"
    "dashboard"
    "syncthing"
    "zortex"
    "glances"
    "nextcloud"
    "immich"
    "borg"
    # "prometheus"
    # "grafana"
  ];

  imports = [
    ./networking.nix
    ./secrets.nix
    ./services.nix
    ../../modules/services
  ];

  nix.settings = {
    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  systemd.tmpfiles.rules =
    let
      groups = lib.mapAttrs (n: v: toString v) config.homelab.groups;
      drives = config.homelab.drives;
    in
    [
      "d ${drives.pubdrive} 0770 ${username} ${groups.serverdata} - -"
      "Z ${drives.pubdrive} 0770 ${username} ${groups.serverdata} - -"
      "d ${drives.personal} 0770 ${username} ${groups.personaldata} - -"
      "Z ${drives.personal} 0770 ${username} ${groups.personaldata} - -"
      "d ${drives.minecraft} 0775 ${username} ${groups.serverdata} - -"
      "Z ${drives.minecraft} 0775 ${username} ${groups.serverdata} - -"
    ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  # fileSystems."/mnt/backup" = {
  #   device = "/dev/disk/by-uuid/D404BD3804BD1E84";
  #   fsType = "ntfs";
  #   options = [
  #     "nofail"
  #     "x-systemd.automount"
  #   ];
  # };
  # fileSystems."/var/lib/nextcloud/data/personal" = {
  #   device = "/srv/sync/personal";
  #   options = [
  #     "bind"
  #     "ro"
  #   ];
  # };

  documentation.man.generateCaches = false; # Fish enables this by default but it takes a lot of time.
  security.sudo.wheelNeedsPassword = false; # So remote building doesn't keep asking for passwords

  # Use generic extlinux compatible bootloader (standard for Pi images)
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # Enable binfmt emulation so you can build this locally on x86
  nixpkgs.hostPlatform = "aarch64-linux";

  zramSwap.enable = true;

  hardware.enableRedistributableFirmware = true;
  hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];

  programs.fish = {
    enable = true;
    shellAliases = {
      ncl = "sudo nixos-container root-login";
      nc = "sudo nixos-container";
      netcat = "/run/current-system/sw/bin/nc";
    };
  };
  users.mutableUsers = false;

  users.users.${username} = {
    isNormalUser = true;
    shell = pkgs.fish;
    hashedPasswordFile = config.sops.secrets.homelab_password_hash.path;
    extraGroups = [
      "serverdata"
      "personaldata"
      "wheel"
      "video"
      "docker"
      "input"
      "uinput"
      "libvirtd"
      "syncthing"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIID64Ajd0fkDjs12IacKz28QzlyedzzaAL8V6YmjTPd/ winston.trey.wilkinson@gmail.com"
    ];
  };

  environment.systemPackages = with pkgs; [
    wol # Wake on LAN util for turning on the PC through ethernet
    wakeonlan
    # wireguard-tools
    syncthing
    tree
    ripgrep
    fd
    lsof
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "24.11";
}
