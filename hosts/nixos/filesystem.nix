{ ... }:
{
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

      # "/" =
      #   { device = "/dev/disk/by-uuid/ce486d8c-d24e-4387-8592-27355e8490c9";
      #     fsType = "ext4";
      #   };

      # "/boot" =
      #   { device = "/dev/disk/by-uuid/09BA-392B";
      #     fsType = "vfat";
      #     options = [ "fmask=0022" "dmask=0022" ];
      #   };

      "/mnt/homelab/misc" = {
        device = "10.1.0.2:/srv/misc";
        fsType = "nfs";
        options = homelabOptions;
      };
      "/mnt/homelab/pubdrive" = {
        device = "10.1.0.2:/srv/pubdrive";
        fsType = "nfs";
        options = homelabOptions;
      };
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
    };
}
