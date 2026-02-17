{
  pkgs,
  lib,
  config,
  ...
}:
let
  homelab = config.homelab;
  cfg = config.homelab.services.borg;
  pc_ip_address = "10.1.0.1";
  mcrconCmd = "${pkgs.mcrcon}/bin/mcrcon -H ${pc_ip_address} -p ${toString homelab.services.mc-server.data.rconPort} -p password";
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

    systemd.services."borgbackup-job-homelab" = {
      unitConfig.OnFailure = "borg-job-failure-notify.service";
      serviceConfig = {
        ReadWritePaths = [
          # Necessary to write the database backups
          "/var/lib/nextcloud"
          "/var/lib/vaultwarden"
          "/var/lib/immich"
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
          -d "The Borg homelab job failed. Check 'journalctl -u borgbackup-job-homelab' for details." \
          http://${homelab.services.ntfy.localEndpoint}/homelab
      '';
    };

    services.borgbackup.jobs."homelab" = {
      repo = "/srv/backup";

      paths = [
        "/srv/sync"
        "/srv/pubdrive"
        "/var/lib/nextcloud"
        "/var/lib/vaultwarden"
        "/var/lib/minecraft"
      ];

      exclude = [
        "*.pyc"
        "/home/*/.cache"

        # Nextcloud
        "*/nextcloud.db-wal"
        "*/nextcloud.db-shm"

        # Minecraft
        "*/logs/latest.log"
        "*.jfr"
        "*.jfr.tmp"
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

        if ! ${pkgs.util-linux}/bin/mountpoint -q /srv/backup; then
          echo "Backup drive not mounted. Skipping backup."
          exit 0
        fi

        # NEXTCLOUD
        echo "Backing up nextcloud..."
        ${pkgs.nixos-container}/bin/nixos-container run nextcloud -- \
          sudo -u postgres ${pkgs.postgresql}/bin/pg_dump -h /run/postgresql nextcloud > /var/lib/nextcloud/nextcloud-sql-dump.sql
        chown ${homelab.username}:${toString homelab.groups.personaldata} /var/lib/nextcloud/nextcloud-sql-dump.sql
        chmod 660 /var/lib/nextcloud/nextcloud-sql-dump.sql

        # VAULTWARDEN
        echo "Backing up vaultwarden..."
        if [ -f /var/lib/vaultwarden/db.sqlite3 ]; then
          ${pkgs.sqlite}/bin/sqlite3 /var/lib/vaultwarden/db.sqlite3 ".backup '/var/lib/vaultwarden/db-backup.sqlite3'"
          chown ${homelab.username}:${toString homelab.groups.personaldata} /var/lib/vaultwarden/db-backup.sqlite3
          chmod 660 /var/lib/vaultwarden/db-backup.sqlite3
        fi

        # IMMICH
        echo "Backing up immich..."
        ${pkgs.nixos-container}/bin/nixos-container run immich -- \
          sudo -u immich ${pkgs.postgresql}/bin/pg_dump immich > /var/lib/immich/immich-sql-dump.sql
        chown ${homelab.username}:${toString homelab.groups.personaldata} /var/lib/immich/immich-sql-dump.sql
        chmod 660 /var/lib/immich/immich-sql-dump.sql

        # MINECRAFT
        echo "Backing up Minecraft..."
        if ${pkgs.iputils}/bin/ping -c 1 -W 2 ${pc_ip_address} > /dev/null; then
          ${mcrconCmd} "save-all"
          ${mcrconCmd} "save-off"
        else
          echo "Minecraft server at ${pc_ip_address} is unreachable. Skipping Minecraft backup."
        fi
      '';

      postHook = lib.mkIf homelab.services.ntfy.enable ''
        if ${pkgs.iputils}/bin/ping -c 1 -W 2 ${pc_ip_address} > /dev/null; then
          ${mcrconCmd} "save-on"
        fi

        # BORG_EXIT_CODE: 0 = success, 1 = warning, 2 = error
        EXIT_CODE="''${BORG_EXIT_CODE:-2}"
        echo $BORG_EXIT_CODE
        if [ "$EXIT_CODE" -eq 0 ]; then
          ${pkgs.curl}/bin/curl \
            -H "Title: Backup Successful" \
            -H "Priority: low" \
            -H "Tags: white_check_mark,backup" \
            -d "Borg finished backing up to /srv/backup successfully." \
            http://${homelab.services.ntfy.localEndpoint}/homelab
        elif [ "$EXIT_CODE" -eq 1 ]; then
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
