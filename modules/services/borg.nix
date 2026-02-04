{
  pkgs,
  lib,
  config,
  ...
}:
let
  homelab = config.homelab;
  cfg = config.homelab.services.borg;
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      borgbackup
    ];
    systemd.tmpfiles.rules = [
      "d /srv/backup 0770 ${homelab.username} ${toString homelab.groups.personaldata}"
      "Z /srv/backup 0770 ${homelab.username} ${toString homelab.groups.personaldata}"
    ];

    systemd.services."borgbackup-job-homelab-backup" = {
      unitConfig.OnFailure = "borg-job-failure-notify.service";
      serviceConfig = {
        ReadWritePaths = [
          "/var/lib/nextcloud"
          "/var/lib/vaultwarden"
        ];
      };
    };

    systemd.services."borg-job-failure-notify" = {
      description = "Notify on Borg job failure";
      serviceConfig = {
        Type = "oneshot";
        User = "root"; # Needs permissions to run curl/access network
      };
      script = ''
        ${pkgs.curl}/bin/curl \
          -H "Title: Backup Failed on ${config.networking.hostName}" \
          -H "Priority: high" \
          -H "Tags: warning,backup" \
          -d "The Borg homelab-backup job failed. Check 'journalctl -u borgbackup-job-homelab-backup' for details." \
          http://${homelab.services.ntfy.localEndpoint}/homelab
      '';
    };

    services.borgbackup.jobs."homelab-backup" = {
      repo = "/srv/backup";

      # What to backup
      paths = [
        "/srv/sync"
        "/var/lib/nextcloud"
        "/var/lib/vaultwarden"
        "/var/lib/minecraft"
      ];

      exclude = [
        "*.pyc"
        "/home/*/.cache"
        "*/nextcloud.db-wal"
        "*/nextcloud.db-shm"
      ];

      # Encryption: 'none' is easiest for a physical drive at home,
      # but 'repokey' is safer if the drive is lost.
      encryption = {
        mode = "none";
      };

      compression = "auto,zstd";

      # Schedule: Run daily at 3:00 AM
      startAt = "daily";

      # Pruning: Keep a "git-log" style history
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 6;
      };

      preHook = ''
        ${pkgs.curl}/bin/curl -d "Borg backing up homelab" http://${homelab.services.ntfy.localEndpoint}/homelab

        # if ! ${pkgs.util-linux}/bin/mountpoint -q /srv/backup; then
        #   echo "Backup drive not mounted. Skipping backup."
        #   exit 0
        # fi

        # Dump Nextcloud (Postgres)
        ${pkgs.nixos-container}/bin/nixos-container run nextcloud -- \
          sudo -u postgres pg_dump nextcloud > /var/lib/nextcloud/nextcloud-sql-dump.sql
        chown ${homelab.username}:${toString homelab.groups.personaldata} /var/lib/nextcloud/nextcloud-sql-dump.sql
        chmod 660 /var/lib/nextcloud/nextcloud-sql-dump.sql

        # Backup Vaultwarden (SQLite)
        if [ -f /var/lib/vaultwarden/db.sqlite3 ]; then
          ${pkgs.sqlite}/bin/sqlite3 /var/lib/vaultwarden/db.sqlite3 ".backup '/var/lib/vaultwarden/db-backup.sqlite3'"
          chown ${homelab.username}:${toString homelab.groups.personaldata} /var/lib/vaultwarden/db-backup.sqlite3
          chmod 660 /var/lib/vaultwarden/db-backup.sqlite3
        fi
      '';

      postHook = ''
        # BORG_EXIT_CODE: 0 = success, 1 = warning, 2 = error
        if [ "$BORG_EXIT_CODE" -eq 0 ]; then
          ${pkgs.curl}/bin/curl \
            -H "Title: Backup Successful" \
            -H "Priority: low" \
            -H "Tags: white_check_mark,backup" \
            -d "Borg finished backing up to /srv/backup successfully." \
            http://${homelab.services.ntfy.localEndpoint}/homelab
        elif [ "$BORG_EXIT_CODE" -eq 1 ]; then
          ${pkgs.curl}/bin/curl \
            -H "Title: Backup Finished with Warnings" \
            -H "Priority: default" \
            -H "Tags: warning,backup" \
            -d "Borg finished with warnings (some files might have been inaccessible)." \
            http://${homelab.services.ntfy.localEndpoint}/homelab
        fi
      '';
    };
  };
}
