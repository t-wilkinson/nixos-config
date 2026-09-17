# hosts/homelab/default.nix
{
  config,
  pkgs,
  username,
  lib,
  ...
}:
{
  imports = [
    ./networking.nix
    ./secrets.nix
    ./services.nix
    ../../modules/homelab
  ];

  homelab.enableServices = [
    "wastebin"
    "ntfy"
    "vault"
    "dashboard"
    "syncthing"
    "zortex"
    "glances"
    # "nextcloud"
    # "immich"
    "borg"
    "mealie"
    "actual-budget"
    # "prometheus"
    # "grafana"
  ];

  services.automatic-timezoned.enable = true;

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
      # "d ${drives.pubdrive} 0770 ${username} ${groups.serverdata} - -"
      # "Z ${drives.pubdrive} 0770 ${username} ${groups.serverdata} - -"
      "d ${drives.personal} 0770 ${username} ${groups.personaldata} - -"
      "Z ${drives.personal} 0770 ${username} ${groups.personaldata} - -"
      "d ${drives.minecraft} 0775 ${username} ${groups.serverdata} - -"
      "Z ${drives.minecraft} 0775 ${username} ${groups.serverdata} - -"
      "d ${drives.actual-budget} 0775 ${username} ${groups.serverdata} - -"
      "Z ${drives.actual-budget} 0775 ${username} ${groups.serverdata} - -"
    ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
  };
  # fileSystems."/srv/pubdrive" = {
  #   device = "10.1.0.1:/pubdrive";
  #   fsType = "nfs4";
  #   options = [
  #     "x-systemd.automount"
  #     "noauto"
  #     "x-systemd.device-timeout=10s" # Fail fast if machine is off
  #     "_netdev" # Wait for network before mounting
  #   ];
  # };

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
    initialPassword = "password";
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
    mcrcon # necessary for accessing mc-server on other pc
    # wol # Wake on LAN util for turning on the PC through ethernet
    wakeonlan
    # wireguard-tools
    syncthing
    tree
    ripgrep
    fd
    lsof
    (pkgs.writeShellApplication {
      name = "wol-pc";
      runtimeInputs = [ pkgs.wakeonlan ];
      text = ''
        wakeonlan -i 10.1.0.1 04:7c:16:e6:d1:10
      '';
    })
    (pkgs.writeShellScriptBin "hl-help" ''
      echo "wol-pc : waake pc on ethernet"
      echo ""
    '')
  ];

  nix.settings = {
    substituters = [
      "https://nix-community.cachix.org"
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "24.11";
}
