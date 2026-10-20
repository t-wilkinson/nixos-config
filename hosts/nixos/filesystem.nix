# The storage HDD, its shares (pubdrive, immich, phones, backups) and the NFS exports/mounts
# between the PC and the Pi come from homelab.storage in ../inventory.nix.
{ config, username, ... }:
let
  storage = config.homelab.storage.volumes.pc-storage;
in
{
  users.groups.storage-media = { };
  users.users.immich.extraGroups = [ "storage-media" ];
  users.users.nextcloud.extraGroups = [ "storage-media" ];
  users.users.${username}.extraGroups = [ "storage-media" ];

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

  fileSystems = {
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

      "${storage.mountPoint}/.snapshots" = {
        inherit (storage) device;
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
