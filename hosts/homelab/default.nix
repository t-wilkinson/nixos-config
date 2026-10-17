# hosts/homelab/default.nix
{
  config,
  pkgs,
  username,
  lib,
  ...
}:
let
  homelab = config.homelab;
  nodes = config.homelab.nodes;
in
{
  imports = [
    ./inventory.nix
    ./networking.nix
    ./secrets.nix
    ./services.nix
    ../../modules/homelab
    ../../modules/sops-check.nix
  ];

  # Services and their hosts are listed in ./inventory.nix
  homelab.thisNode = "pi";

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
    # d(D) := create (empty) directory
    # z(Z) := (recursively) modifies path
    # f(F) := creates a (truncated) file
    [
      # Type  Path                  Mode  User Group Age Argument
      "d      /srv                  0701  ${username}    -     -   -"
      "z      /srv                  0701  ${username}    -     -   -"
      "d      /srv/sync             0701  ${username}    -     -   -"
      "z      /srv/sync             0701  ${username}    -     -   -"

      # /srv/sync/personal: owned by personaldata, traversal-only for zortexdata
      "d ${drives.personal} 2770 ${username} ${groups.personaldata} - -"
      "z ${drives.personal} 2770 ${username} ${groups.personaldata} - -"
      "a ${drives.personal} -    -          -                    - group:${groups.zortexdata}:--x"

      # /srv/sync/personal/notes: read-only for zortexdata
      "d ${drives.personal}/notes 2770 ${username} ${groups.personaldata} - -"
      # Apply access ACL recursively to existing contents, and default ACL to notes directory
      "A ${drives.personal}/notes - - - - group:${groups.zortexdata}:rwx"
      "a ${drives.personal}/notes - - - - default:group:${groups.zortexdata}:rwx"

      "d ${drives.pi-pubdrive} 2770 ${username} ${groups.storage-media} - -"
      "Z ${drives.pi-pubdrive} 2770 ${username} ${groups.storage-media} - -"
      "d ${drives.minecraft} 2775 ${username} ${groups.serverdata} - -"
      "Z ${drives.minecraft} 2775 ${username} ${groups.serverdata} - -"
      "d ${drives.actual-budget} 2775 ${username} ${groups.serverdata} - -"
      "Z ${drives.actual-budget} 2775 ${username} ${groups.serverdata} - -"
    ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
  };
  fileSystems."${homelab.drives.pi-pubdrive}" = {
    device = "${homelab.nodes.pc.ipv4}:/pubdrive";
    fsType = "nfs4";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.device-timeout=10s" # Fail fast if machine is off
      "x-systemd.after=network-online.target"
      "_netdev" # Wait for network before mounting
    ];
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
    # initialPassword = "password";
    hashedPasswordFile = config.sops.secrets.homelab_password_hash.path;
    extraGroups = [
      "serverdata"
      "personaldata"
      "storage-media"
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
        wakeonlan -i ${nodes.pc.ipv4} ${nodes.pc.mac}
      '';
    })
    (pkgs.writeShellScriptBin "hl-help" ''
      echo "wol-pc : wake pc on ethernet"
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
