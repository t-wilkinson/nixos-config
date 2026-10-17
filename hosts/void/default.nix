# hosts/void/default.nix
# "void": a blank NixOS you can reach over the network, used to bring up a new machine before
# it gets its real configuration. Built as images (flake.nix `images.void-*`):
#   void-iso   x86_64 installer ISO   -> write to a USB stick, boot, install from it
#   void-disk  x86_64 raw EFI disk    -> write straight to the target drive, boot it
#   void-sd    aarch64 SD-card image  -> write to an SD card / USB SSD for a Pi
# All of them boot with:
#   - SSH as root with the admin keys from hosts/homelab/inventory.nix (key only)
#   - mDNS, so `ssh root@void.local` works on the LAN without knowing the address
#   - NetworkManager (`nmtui` for Wi-Fi), Tailscale (run `tailscale up` to join the tailnet)
#   - flakes, git, and the usual install tools
# Then deploy the real configuration onto it (see docs/new-machine.md).
{
  lib,
  pkgs,
  username,
  ...
}:
let
  inventory = (import ../homelab/inventory.nix { inherit username; }).homelab;
  isx86 = pkgs.stdenv.hostPlatform.isx86_64;
in
{
  networking.hostName = lib.mkDefault "void";
  networking.networkmanager.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = lib.mkForce "prohibit-password"; # the installer profile defaults to "yes"
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
  users.users.root.openssh.authorizedKeys.keys = inventory.adminKeys;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  services.tailscale.enable = true;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "root" ];
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    rsync
    htop
    parted
    gptfdisk
    ssh-to-age # derive a host's age key from its SSH host key, for .sops.yaml
  ];

  # Defaults for the plain configuration (the image variants bring their own disk layout)
  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  boot.loader = lib.mkMerge [
    { grub.enable = lib.mkDefault false; }
    (lib.mkIf isx86 {
      systemd-boot.enable = lib.mkDefault true;
      efi.canTouchEfiVariables = lib.mkDefault false; # the disk image may boot on any machine
    })
    (lib.mkIf (!isx86) { generic-extlinux-compatible.enable = lib.mkDefault true; })
  ];

  boot.zfs.forceImportRoot = false; # no ZFS root here (silences the 26.05 warning)

  system.stateVersion = "26.05";
}
