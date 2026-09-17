{ config, username, ... }:
let
  homelab = config.homelab;
in
{
  users.groups.storage-media = { };
  users.users.immich.extraGroups = [ "storage-media" ];
  users.users.nextcloud.extraGroups = [ "storage-media" ];
  users.users.${username}.extraGroups = [ "storage-media" ];

  # FILE SETTINGS
  systemd.tmpfiles.rules = [
    # Type Path Mode User Group Age Argument
    "d ${homelab.drives.pubdrive} 2770 ${username} storage-media"
    "Z ${homelab.drives.pubdrive} 2770 ${username} storage-media"
    # "a+   /mnt/storage/pubdrive     -    -    -             -   u:nextcloud:rX,u:immich:rX,g:storage-media:rwX"
    # "a+   /mnt/storage/pubdrive     -    -    -             -   d:u:nextcloud:rwX,d:u:immich:rwX,d:g:storage-media:rwX"
  ];

  # SWAP
  swapDevices = [
    {
      device = "/dev/disk/by-id/nvme-CT1000P5PSSD8_2316402A1248-part2";
      # size = 16 * 1024;
    }
  ];

  zramSwap = {
    enable = true;
    # memoryPercent = 50;
    # priority = 5;
  };

  # ZFS
  networking.hostId = "73e662d7";
  services.zfs.autoScrub.enable = true;
  services.zfs.autoSnapshot = {
    enable = true;
    flags = "-k";
  };
  boot.supportedFilesystems = [ "zfs" ];

  services.nfs.server = {
    enable = true;
    exports = ''
      /mnt/storage 10.1.0.2(rw,sync,no_subtree_check,crossmnt,fsid=0,no_root_squash)
    '';
  };

  fileSystems =
    let
      homelabOptions = [
        "x-systemd.automount"
        "x-systemd.idle-timeout=10"
        "x-systemd.mount-timeout=10s"
        "x-systemd.after=network-online.target"
        "noauto"
        "_netdev"
      ];
    in
    {
      "/" = {
        device = "rpool/root";
        fsType = "zfs";
      };

      "/nix" = {
        device = "rpool/nix";
        fsType = "zfs";
      };

      "/home" = {
        device = "rpool/home";
        fsType = "zfs";
      };

      "/boot" = {
        device = "/dev/disk/by-id/nvme-CT1000P5PSSD8_2316402A1248-part1";
        fsType = "vfat";
        options = [
          "nofail"
          "fmask=0022"
          "dmask=0022"
        ];
      };

      # "/" =
      #   { device = "/dev/disk/by-uuid/ce486d8c-d24e-4387-8592-27355e8490c9";
      #     fsType = "ext4";
      #   };

      # "/boot" =
      #   { device = "/dev/disk/by-uuid/09BA-392B";
      #     fsType = "vfat";
      #     options = [ "fmask=0022" "dmask=0022" ];
      #   };

      # "/mnt/homelab/misc" = {
      #   device = "10.1.0.2:/srv/misc";
      #   fsType = "nfs";
      #   options = homelabOptions;
      # };
      # "/mnt/homelab/pubdrive" = {
      #   device = "10.1.0.2:/srv/pubdrive";
      #   fsType = "nfs";
      #   options = homelabOptions;
      # };
      "/mnt/homelab/personal" = {
        device = "10.1.0.2:/srv/sync/personal";
        fsType = "nfs";
        options = homelabOptions;
      };
      "/var/lib/minecraft" = {
        device = "10.1.0.2:/var/lib/minecraft";
        fsType = "nfs";
        options = homelabOptions ++ [
          "rw"
          "soft"
        ]; # Only mount when accessed
      };
      "/mnt/storage" = {
        device = "/dev/disk/by-uuid/a92044b3-8a07-43d8-a676-abbac9f6e667";
        fsType = "btrfs";
        options = [
          "subvol=@data"
          "compress=no"
          "noatime"
          "noatime"
          "x-systemd.device-timeout=10s"
        ];
      };

      "/mnt/storage/.snapshots" = {
        device = "/dev/disk/by-uuid/a92044b3-8a07-43d8-a676-abbac9f6e667";
        fsType = "btrfs";
        options = [
          "subvol=@snapshots"
          "compress=zstd:1"
          "noatime"
          "space_cache=v2"
        ];
      };
    };
}
