# hosts/homelab/default.nix
{
  config,
  pkgs,
  lib,
  username,
  ...
}:
{
  my-lab = {
    domain = "home.lab";
    vpnIP = "10.100.0.1";
    vpnNetwork = "10.100.0";
    publicDomain = "treywilkinson.com";
  };

  imports = [
    ./networking.nix
    ./secrets.nix
    ./services.nix
    ./services/backups.nix
    # ./services/caddy.nix
    ./services/cloud.nix
    ./services/monitoring.nix
  ];

  nix.settings = {
    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  documentation.man.generateCaches = false; # Fish enables this by default but it takes a lot of time.
  security.sudo.wheelNeedsPassword = false; # So remote building doesn't keep asking for passwords

  # Use generic extlinux compatible bootloader (standard for Pi images)
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # Enable binfmt emulation so you can build this locally on x86
  nixpkgs.hostPlatform = "aarch64-linux";

  zramSwap.enable = true;

  systemd.tmpfiles.rules = [
    "d /srv/sync/personal/drive 0770 ${username} personaldata - -"
    "Z /srv/sync/personal/drive 0770 ${username} personaldata - -"
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  fileSystems."/mnt/backup" = {
    device = "/dev/disk/by-uuid/D404BD3804BD1E84";
    fsType = "ntfs";
    options = [
      "nofail"
      "x-systemd.automount"
    ];
  };
  # fileSystems."/var/lib/nextcloud/data/personal" = {
  #   device = "/srv/sync/personal";
  #   options = [
  #     "bind"
  #     "ro"
  #   ];
  # };

  hardware.enableRedistributableFirmware = true;
  hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];

  programs.fish.enable = true;
  users.mutableUsers = false;
  users.groups.personaldata = { }; # for exposing to synced directory to nextcloud
  users.users.${username} = {
    isNormalUser = true;
    shell = pkgs.fish;
    hashedPasswordFile = config.sops.secrets.homelab_password_hash.path;
    extraGroups = [
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

  # Provision the SSH key generated in Phase 1
  # environment.etc."ssh/ssh_host_ed25519_key" = {
  #   source = ./ssh_host_ed25519_key;
  #   mode = "0600";
  # };

  environment.systemPackages = with pkgs; [
    wol # Wake on LAN util for turning on the PC through ethernet
    wireguard-tools
    syncthing
    tree
    ripgrep
    fd
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "24.11";
}
