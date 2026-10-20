{
  pkgs,
  lib,
  config,
  ...
}:
let
  homelab = config.homelab;
  cfg = config.homelab.services.borg;
  secrets = config.sops.secrets;
  mc = homelab.services.mc-server;
  pc_ip_address = homelab.nodes.${mc.host}.ipv4;
  shares = homelab.storage.shares;
  repo = "${shares.backup.path}/homelab"; # /srv/backup/homelab
  # Password comes from the environment (MCRCON_PASS) so it never shows up in `ps`.
  # -P is the port; -p would be the password.
  mcrconCmd = "MCRCON_PASS=\"$(cat ${secrets.minecraft_rcon_pass.path})\" ${pkgs.mcrcon}/bin/mcrcon -H ${pc_ip_address} -P ${toString mc.data.rconPort}";
  # ntfy requires auth (deny-all); the header file is rendered by sops (see hosts/homelab/secrets.nix)
  ntfyCurl = "${pkgs.curl}/bin/curl -sS -H @${config.sops.templates."ntfy-auth-header".path}";
in
{
  config = lib.mkIf cfg.runsHere {
    environment.systemPackages = with pkgs; [
      borgbackup
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
        ${ntfyCurl} \
          -H "Title: Backup Failed on ${config.networking.hostName}" \
          -H "Priority: high" \
          -H "Tags: warning,backup" \
          -d "The Borg homelab job failed. Check 'journalctl -u borgbackup-job-homelab' for details." \
          http://${homelab.services.ntfy.localEndpoint}/homelab
      '';
    };

    services.borgbackup.jobs."homelab" = {
      # A directory on the Pi's drive (the backup share, /srv/backup). The PC keeps a copy of
      # this repo (borg-mirror.nix); the PC's archive next to it (pc-archive) is not in here.
      inherit repo;

      # Wait for the lock instead of failing while the PC is copying the repo
      extraArgs = [
        "--lock-wait"
        "3600"
      ];

      paths = [
        "/srv/sync"
        "/var/lib/nextcloud"
        "/var/lib/vaultwarden"
        shares.minecraft.path
        shares.actual-budget.path
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

      # repokey: the key sits in the repo, protected by borg_pass. Keep an offline copy of
      # `borg key export /srv/backup/homelab` too; without key + passphrase the backups are gone.
      # (The PC's copy of the repo has the key inside it, but still needs the passphrase.)
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat ${secrets.borg_pass.path}";
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
        ${lib.optionalString homelab.services.ntfy.enable ''
          ${ntfyCurl} -d "Borg backing up homelab" http://${homelab.services.ntfy.localEndpoint}/homelab || true
        ''}
        # NEXTCLOUD
        # echo "Backing up nextcloud..."
        # ${pkgs.nixos-container}/bin/nixos-container run nextcloud -- \
        #   sudo -u postgres ${pkgs.postgresql}/bin/pg_dump -h /run/postgresql nextcloud > /var/lib/nextcloud/nextcloud-sql-dump.sql
        # chown ${homelab.username}:${toString homelab.groups.personaldata} /var/lib/nextcloud/nextcloud-sql-dump.sql
        # chmod 660 /var/lib/nextcloud/nextcloud-sql-dump.sql

        # VAULTWARDEN
        echo "Backing up vaultwarden..."
        if [ -f /var/lib/vaultwarden/db.sqlite3 ]; then
          ${pkgs.sqlite}/bin/sqlite3 /var/lib/vaultwarden/db.sqlite3 ".backup '/var/lib/vaultwarden/db-backup.sqlite3'"
          chown ${homelab.username}:${toString homelab.groups.personaldata} /var/lib/vaultwarden/db-backup.sqlite3
          chmod 660 /var/lib/vaultwarden/db-backup.sqlite3
        fi

        # IMMICH
        # echo "Backing up immich..."
        # ${pkgs.nixos-container}/bin/nixos-container run immich -- \
        #   sudo -u immich ${pkgs.postgresql}/bin/pg_dump immich > /var/lib/immich/immich-sql-dump.sql
        # chown ${homelab.username}:${toString homelab.groups.personaldata} /var/lib/immich/immich-sql-dump.sql
        # chmod 660 /var/lib/immich/immich-sql-dump.sql

        # MINECRAFT: flush and pause saving while the world is copied. Only when the server is
        # enabled, and never fatal: the script runs under set -e, and a PC that's awake without
        # the server running would otherwise fail the whole backup.
        ${lib.optionalString mc.enable ''
          echo "Backing up Minecraft..."
          if ${pkgs.iputils}/bin/ping -c 1 -W 2 ${pc_ip_address} > /dev/null; then
            ${mcrconCmd} "save-all" && ${mcrconCmd} "save-off" || echo "Minecraft RCON unavailable; copying the world as is."
          else
            echo "Minecraft server at ${pc_ip_address} is unreachable. Skipping Minecraft flush."
          fi
        ''}
      '';

      # Runs on exit, success or not; the job's exit status is $exitStatus (0 = success,
      # 1 = warning, 2 = error). Failures notify through OnFailure above.
      postHook =
        lib.optionalString mc.enable ''
          if ${pkgs.iputils}/bin/ping -c 1 -W 2 ${pc_ip_address} > /dev/null; then
            ${mcrconCmd} "save-on" || true
          fi
        ''
      + lib.optionalString homelab.services.ntfy.enable ''
        if [ "$exitStatus" -eq 0 ]; then
          ${ntfyCurl} \
            -H "Title: Backup Successful" \
            -H "Priority: low" \
            -H "Tags: white_check_mark,backup" \
            -d "Borg finished backing up to ${repo} successfully." \
            http://${homelab.services.ntfy.localEndpoint}/homelab
        elif [ "$exitStatus" -eq 1 ]; then
          ${ntfyCurl} \
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
