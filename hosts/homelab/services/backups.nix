{
  username,
  pkgs,
  config,
  ...
}:
{
  # SYNCTHING
  # systemd.services.syncthing.serviceConfig = {
  #   StateDirectory = "syncthing";
  #   StateDirectoryMode = "0750";
  # };
  systemd.tmpfiles.rules = [
    "d /srv/sync 0700 - - -"
    "d /srv/sync/personal 0770 - personaldata -"
  ];
  services.syncthing = {
    enable = true;
    user = username;
    configDir = "/home/${username}/.config/syncthing";
    dataDir = "/srv/sync"; # default folder for new synced files

    openDefaultPorts = true; # 22000/tcp transfer, 21027/udp discovery

    guiAddress = "127.0.0.1:${toString config.my-lab.services.sync.port}";

    settings = {
      gui.insecureSkipHostcheck = true;
      options = {
        # nattEnabled = false;
      };

      devices = {
        "nixos" = {
          id = "X6Q657S-5M3JA3P-MMWO5VX-EPHF7BB-XQI3MPS-NV2NFSA-BCPHPOV-VFCRZAG";
          # addresses = [ "tcp://10.1.0.1:22000" ];
          # introducer = true;
        };
        "macos" = {
          id = "A6IABFJ-IS7YU6H-RASNO76-KLURNQV-QRU676J-K4GXR2H-6P2733W-ORLEMQU";
          # introducer = true;
        };
      };

      folders = {
        "personal" = {
          id = "personal"; # remove this line?
          path = "/srv/sync/personal";
          devices = [ "nixos" ];
          versioning = {
            type = "simple";
            params = {
              keep = "10";
            };
          };
        };
      };
    };
  };

  # BORG backup
  services.borgbackup.jobs."homelab-backup" = {
    # Define what to backup
    paths = [
      "/var/lib/nextcloud" # Example: Nextcloud data
      "/srv/sync"
    ];

    # Exclude temporary junk
    exclude = [
      "*.pyc"
      "/home/*/.cache"
      "*/nextcloud.db-wal"
      "*/nextcloud.db-shm"
    ];

    # The location on the USB drive
    repo = "/mnt/backup/borg";

    # Encryption: 'none' is easiest for a physical drive at home,
    # but 'repokey' is safer if the drive is lost.
    encryption = {
      mode = "none";
    };

    # Compression (zstd is fast and efficient)
    compression = "auto,zstd";

    # Schedule: Run daily at 3:00 AM
    startAt = "daily";

    # Pruning: Keep a "git-log" style history
    prune.keep = {
      daily = 7;
      weekly = 4;
      monthly = 6;
    };

    # This prevents the backup from creating a messy folder if the drive isn't there.
    preHook = ''
      if ! ${pkgs.util-linux}/bin/mountpoint -q /mnt/backup; then
        echo "Backup drive not mounted. Skipping backup."
        exit 0
      fi
    '';
  };
}
