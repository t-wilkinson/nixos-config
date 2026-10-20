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
    ../inventory.nix
    ./networking.nix
    ./wifi.nix
    ./secrets.nix
    ../../modules/homelab
    ../../modules/sops-check.nix
  ];

  # Services and their hosts are listed in ../inventory.nix
  homelab.thisNode = "pi";

  services.automatic-timezoned.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password"; # key only: deploy-rs connects as root
    };
  };
  users.users.root.openssh.authorizedKeys.keys = homelab.adminKeys;

  # Only root may hand the daemon unsigned store paths. Deploys (deploy-rs) log in as root with
  # an SSH key, so the admin user needs neither trusted-users nor passwordless sudo.
  nix.settings.trusted-users = [ "root" ];

  systemd.tmpfiles.rules =
    let
      groups = lib.mapAttrs (n: v: toString v) config.homelab.groups;
      personal = config.homelab.storage.shares.personal.path;
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

      # Share directories (personal, backup, minecraft, ...) and the NFS mount of the PC's
      # pubdrive come from homelab.storage in ../inventory.nix.

      # /srv/sync/personal: traversal-only for zortexdata
      "a ${personal} -    -          -                    - group:${groups.zortexdata}:--x"

      # /srv/sync/personal/notes: read-only for zortexdata
      "d ${personal}/notes 2770 ${username} ${groups.personaldata} - -"
      # Apply access ACL recursively to existing contents, and default ACL to notes directory
      "A ${personal}/notes - - - - group:${groups.zortexdata}:rwx"
      "a ${personal}/notes - - - - default:group:${groups.zortexdata}:rwx"
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

  documentation.man.cache.enable = false; # Fish enables this by default but it takes a lot of time.
  boot.zfs.forceImportRoot = false; # no ZFS here; silences the 26.05 warning about the old default
  # sudo asks for the user's password (homelab_password_hash); deploys use root over SSH instead
  security.sudo.wheelNeedsPassword = true;

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
    openssh.authorizedKeys.keys = homelab.adminKeys; # inventory.nix
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
    cloudflared
    (pkgs.writeShellApplication {
      name = "wol-pc";
      runtimeInputs = [ pkgs.wakeonlan ];
      text = ''
        # Broadcast on the direct link: a sleeping PC has no ARP entry, so its IP is unreachable
        wakeonlan -i ${homelab.network.broadcast} -p 9 ${nodes.pc.mac}
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
