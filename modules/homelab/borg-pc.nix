# modules/homelab/borg-pc.nix
#
# PC -> Pi: nightly encrypted backup of the PC's databases and Nextcloud's own data.
#
#   - Databases: pg_dump of Nextcloud and Immich (albums, people, faces, OCR, smart search,
#     metadata), plus the cluster's roles. Taken fresh before every run.
#   - /var/lib/nextcloud: config and users' files (previews excluded, they regenerate).
#   - /etc/ssh: host keys; sops decrypts this machine's secrets with the ed25519 one.
#
# The repo is /srv/backup/pc on the Pi. The PC reaches it as user borg-pc, whose key can only
# run `borg serve --append-only` on that one repo: a compromised PC can add backups but not
# delete or rewrite old ones. Pruning happens on the Pi (borg-pc-prune, weekly), which the PC
# can't influence.
#
# Photos and documents in pubdrive are NOT in here (too big; copy them by hand with
# apps/homelab/copy-to-pi). Immich's thumbnails and encoded videos regenerate from the photos.
#
# Restore, on the PC:  BORG_RSH=... borg list borg-pc@<pi>:/srv/backup/pc
# (or on the Pi as root: borg list /srv/backup/pc). Passphrase: borg_pass, as for the Pi's repo.
#   pg_restore -d nextcloud nextcloud.dump   (after psql -f globals.sql)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  hl = config.homelab;
  cfg = hl.services.borg-pc;
  host = hl.nodes.${cfg.host}; # the PC
  target = hl.nodes.${cfg.data.target}; # the Pi
  repo = hl.storage.shares.${cfg.data.share}.path; # /srv/backup/pc on the Pi
  dumpDir = "/var/backup/borg-pc";
  stateDir = "/var/lib/borg-pc";
  canNotify = hl.services.ntfy.enable && config.sops.secrets ? ntfy_auth;
  ssh = "ssh -i ${host.backupKeyFile} -o UserKnownHostsFile=${stateDir}/known_hosts -o StrictHostKeyChecking=accept-new -o BatchMode=yes";
  pg = config.services.postgresql.package;
  borg = "${pkgs.borgbackup}/bin/borg";
in
lib.mkIf cfg.enable (
  lib.mkMerge [
    {
      assertions = [
        {
          assertion = host.backupKey != null && host.backupKeyFile != null;
          message = "homelab.services.borg-pc needs homelab.nodes.${cfg.host}.backupKey and backupKeyFile.";
        }
        {
          assertion = hl.storage.shares.${cfg.data.share}.node == cfg.data.target;
          message = "homelab.services.borg-pc: share ${cfg.data.share} must be on ${cfg.data.target}.";
        }
      ];
    }

    # PC: dump and push
    (lib.mkIf cfg.runsHere {
      # borg_pass from the Pi's secrets file (this machine's age key can decrypt it too)
      sops.secrets.borg_pass = {
        sopsFile = ../../hosts/homelab/secrets.yaml;
        owner = "root";
        mode = "0400";
      };

      systemd.tmpfiles.rules = [
        "d ${dumpDir} 0700 root root - -"
        "d ${stateDir} 0700 root root - -"
      ];

      services.borgbackup.jobs.pc = {
        repo = "borg-pc@${target.ipv4}:${repo}";
        environment.BORG_RSH = ssh;
        extraArgs = [
          "--lock-wait"
          "600"
        ];

        paths = [
          dumpDir
          "/var/lib/nextcloud"
          "/etc/ssh"
        ];
        readWritePaths = [
          dumpDir
          stateDir # known_hosts
        ];
        exclude = [
          "/var/lib/nextcloud/data/appdata_*/preview"
          "/var/lib/nextcloud/data/*/cache"
          "/var/lib/nextcloud/data/nextcloud.log"
        ];

        encryption = {
          mode = "repokey-blake2";
          passCommand = "cat ${config.sops.secrets.borg_pass.path}";
        };
        compression = "auto,zstd";

        # 04:00, or as soon as the PC wakes; waits for the network (persistent + remote repo)
        startAt = "*-*-* 04:00";
        persistentTimer = true;
        # No prune here: the repo is append-only for this machine. The Pi prunes it.

        preHook = ''
          # Fresh database dumps (custom format, restore with pg_restore), plus roles
          rm -f ${dumpDir}/*
          ${pkgs.util-linux}/bin/runuser -u postgres -- ${pg}/bin/pg_dumpall --globals-only > ${dumpDir}/globals.sql
          for db in ${lib.concatStringsSep " " cfg.data.databases}; do
            if ${pkgs.util-linux}/bin/runuser -u postgres -- ${pg}/bin/psql -tAc "select 1 from pg_database where datname = '$db'" | grep -q 1; then
              echo "Dumping $db..."
              ${pkgs.util-linux}/bin/runuser -u postgres -- ${pg}/bin/pg_dump -Fc "$db" > ${dumpDir}/"$db".dump
            else
              echo "warning: database $db does not exist, skipped" >&2
            fi
          done
          ls -lh ${dumpDir}
        '';
      };

      systemd.services.borgbackup-job-pc = {
        unitConfig.OnFailure = lib.optional canNotify "borg-pc-failure-notify.service";
        after = [ "postgresql.service" ];
        path = [ pkgs.gnugrep ];
      };
      systemd.services.borg-pc-failure-notify = lib.mkIf canNotify {
        description = "Notify that the PC's database backup failed";
        serviceConfig.Type = "oneshot";
        script = ''
          ${pkgs.curl}/bin/curl -sS -H "Authorization: Bearer $(cat ${config.sops.secrets.ntfy_auth.path})" \
            -H "Title: PC backup failed on ${config.networking.hostName}" \
            -H "Priority: high" -H "Tags: warning,backup" \
            -d "Check 'journalctl -u borgbackup-job-pc' for details." \
            https://${hl.services.ntfy.domain}/homelab
        '';
      };
    })

    # Pi: an append-only borg endpoint for the PC, and the pruning the PC isn't allowed to do
    (lib.mkIf (hl.thisNode == cfg.data.target) {
      users.groups.borg-pc = { };
      users.users.borg-pc = {
        isSystemUser = true;
        group = "borg-pc";
        home = repo;
        shell = pkgs.bashInteractive; # sshd runs the forced command through the login shell
        openssh.authorizedKeys.keys = lib.optional (host.backupKey != null)
          ''restrict,command="${borg} serve --append-only --restrict-to-repository ${repo}" ${host.backupKey}'';
      };

      systemd.services.borg-pc-prune = {
        description = "Prune the PC's borg repo";
        unitConfig.ConditionPathExists = "${repo}/config"; # nothing to do before the first backup
        serviceConfig = {
          Type = "oneshot";
          User = "borg-pc";
          Group = "borg-pc";
          StateDirectory = "borg-pc-prune"; # borg's cache, kept out of the repo directory
          LoadCredential = "pass:${config.sops.secrets.borg_pass.path}";
          IOSchedulingClass = "idle";
        };
        environment.BORG_BASE_DIR = "/var/lib/borg-pc-prune";
        script = ''
          export BORG_PASSCOMMAND="cat $CREDENTIALS_DIRECTORY/pass"
          ${borg} prune --lock-wait 3600 --list \
            --keep-daily ${toString cfg.data.keep.daily} \
            --keep-weekly ${toString cfg.data.keep.weekly} \
            --keep-monthly ${toString cfg.data.keep.monthly} \
            ${repo}
          ${borg} compact --lock-wait 3600 ${repo}
        '';
        startAt = "Sun 05:30";
      };
      systemd.timers.borg-pc-prune.timerConfig.Persistent = true;
    })
  ]
)
