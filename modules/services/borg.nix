{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.homelab.services.borg;
in
{
  config = lib.mkIf cfg.enable {
    # BORG backup
    services.borgbackup.jobs."homelab-backup" = {
      # Define what to backup
      paths = [
        "/var/lib/nextcloud"
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
  };
}
