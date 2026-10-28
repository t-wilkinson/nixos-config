# modules/homelab/borg.nix
#
# Nightly encrypted backup of the Pi's state to /srv/backup/homelab (a folder on the Pi's drive).
# The PC keeps a copy of the repo (./borg-mirror.nix), so a dead Pi drive doesn't take the
# backups with it.
#
# What is backed up: all service state (/var/lib), synced files (/srv/sync), the admin's home
# (Syncthing's identity lives there) and /etc/ssh (host keys and the sops age key, so a restored
# Pi keeps its identity and can decrypt its secrets).
#
# SQLite databases are copied consistently first (sqlite3 .backup into /var/lib/borg-db-dumps);
# the live files are backed up too, but may be mid-write. Restore from the dump.
#
# To restore: borg list /srv/backup/homelab (passphrase: borg_pass in hosts/homelab/secrets.yaml,
# which your own age key can also decrypt). Keep that key, and `borg key export`, off the Pi.
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
  dumpDir = "/var/lib/borg-db-dumps";
  # Password comes from the environment (MCRCON_PASS) so it never shows up in `ps`.
  # -P is the port; -p would be the password.
  mcrconCmd = "MCRCON_PASS=\"$(cat ${secrets.minecraft_rcon_pass.path})\" ${pkgs.mcrcon}/bin/mcrcon -H ${pc_ip_address} -P ${toString mc.data.rconPort}";
  # ntfy requires auth (deny-all); the header file is rendered by sops (see hosts/homelab/secrets.nix)
  ntfyCurl = "${pkgs.curl}/bin/curl -sS -H @${config.sops.templates."ntfy-auth-header".path}";
  ntfyUrl = "http://${homelab.services.ntfy.localEndpoint}/homelab";
  # Jobs report every run to Gatus (./jobs.nix), which alerts on failures and missed runs;
  # without it (no gatus_push_token yet), failures notify ntfy directly
  ownNotify = homelab.services.ntfy.enable && !homelab.jobReports.enable;

  notifyFailure = unit: what: {
    description = "Notify that ${what} failed";
    serviceConfig.Type = "oneshot";
    script = lib.optionalString ownNotify ''
      ${ntfyCurl} \
        -H "Title: ${what} failed on ${config.networking.hostName}" \
        -H "Priority: high" \
        -H "Tags: warning,backup" \
        -d "Check 'journalctl -u ${unit}' for details." \
        ${ntfyUrl}
    '';
  };
in
{
  config = lib.mkMerge [
    {
      # Reported to Gatus (./jobs.nix); registered on every node so Gatus on the Pi knows them
      homelab.jobs = lib.mkIf cfg.enable {
        borg-homelab = {
          name = "Pi backup";
          node = cfg.host;
          unit = "borgbackup-job-homelab";
          heartbeat = "26h"; # nightly
        };
        borg-check = {
          name = "Pi backup check";
          node = cfg.host;
          unit = "borg-check";
          heartbeat = "768h"; # monthly (32 days)
        };
      };
    }

    (lib.mkIf cfg.runsHere {
      environment.systemPackages = with pkgs; [
        borgbackup
      ];

      systemd.services."borgbackup-job-homelab" = {
        unitConfig.OnFailure = lib.optional ownNotify "borg-job-failure-notify.service";
        # systemd creates ${dumpDir} on every start, before it sets up the sandbox, and makes it
        # writable despite the job's ProtectSystem=strict. (A ReadWritePaths entry that doesn't
        # exist yet fails the whole unit with 226/NAMESPACE.) 0700: the dumps include
        # Vaultwarden's and Authelia's databases.
        serviceConfig.StateDirectory = "borg-db-dumps";
        serviceConfig.StateDirectoryMode = "0700";
      };
      systemd.services."borg-job-failure-notify" = notifyFailure "borgbackup-job-homelab" "Backup";

      # Monthly: check the repo and every archive's metadata (not the file contents themselves;
      # that is `borg check --verify-data`, worth running by hand once in a while).
      systemd.services.borg-check = {
        description = "Check the homelab borg repo";
        unitConfig.OnFailure = lib.optional ownNotify "borg-check-failure-notify.service";
        serviceConfig = {
          Type = "oneshot";
          CPUSchedulingPolicy = "idle";
          IOSchedulingClass = "idle";
        };
        environment.BORG_PASSCOMMAND = "cat ${secrets.borg_pass.path}";
        script = "${pkgs.borgbackup}/bin/borg check --lock-wait 3600 ${repo}";
        startAt = "*-*-01 05:00";
      };
      systemd.timers.borg-check.timerConfig.Persistent = true;
      systemd.services.borg-check-failure-notify = notifyFailure "borg-check" "Backup check";

      services.borgbackup.jobs."homelab" = {
        inherit repo;

        # Wait for the lock instead of failing while the PC is copying the repo
        extraArgs = [
          "--lock-wait"
          "3600"
        ];

        paths = [
          "/srv/sync"
          "/var/lib" # every service's state, including the database dumps below
          "/home/${homelab.username}" # Syncthing's config and keys
          "/etc/ssh" # host keys and the sops age key
        ];

        # /var/lib and /srv/sync are live, so borg regularly warns (exit 1) that a file changed
        # while it was read. With the default (true) that fails the job: the archive keeps its
        # .failed suffix, prune/compact are skipped and the failure alert fires. Real errors
        # (exit 2) still fail it.
        failOnWarnings = false;

        exclude = [
          "*.pyc"
          "/home/*/.cache"
          "/var/lib/systemd/coredump"
          "/var/lib/docker"
          "/var/lib/containers/storage"
          "/var/lib/nixos-containers/*/nix" # containers share the host's /nix/store

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

        # 03:00, before the PC's daily copy of the repo (borg-mirror, 06:00 or on wake)
        startAt = "*-*-* 03:00";
        persistentTimer = true; # catch up after a power cut

        # Pruning: Keep a "git-log" style history
        prune.keep = {
          daily = 7;
          weekly = 4;
          monthly = 6;
        };

        preHook = ''
          ${lib.optionalString ownNotify ''
            ${ntfyCurl} -d "Borg backing up homelab" ${ntfyUrl} || true
          ''}
          # SQLITE: a consistent copy of every SQLite database under /var/lib (Vaultwarden,
          # Authelia, ntfy, Beszel, Mealie, Actual, ...), read-only, so services keep running.
          # A database that can't be copied is a warning, not a failed backup.
          rm -rf ${dumpDir}/*
          find /var/lib -xdev -path ${dumpDir} -prune -o -type f \
            \( -name '*.db' -o -name '*.sqlite' -o -name '*.sqlite3' \) -size +0 -print0 |
            while IFS= read -r -d "" f; do
              [ "$(head -c 15 "$f")" = "SQLite format 3" ] || continue
              out="${dumpDir}$f"
              mkdir -p "$(dirname "$out")"
              ${pkgs.sqlite}/bin/sqlite3 -readonly "$f" ".timeout 10000" ".backup '$out'" \
                || echo "warning: could not snapshot $f" >&2
            done
          echo "SQLite snapshots: $(find ${dumpDir} -type f | wc -l)"

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
        # including borg warnings since failOnWarnings = false; anything else = failed).
        # Failures notify through OnFailure above.
        postHook =
          lib.optionalString mc.enable ''
            if ${pkgs.iputils}/bin/ping -c 1 -W 2 ${pc_ip_address} > /dev/null; then
              ${mcrconCmd} "save-on" || true
            fi
          ''
          + lib.optionalString ownNotify ''
            if [ "$exitStatus" -eq 0 ]; then
              ${ntfyCurl} \
                -H "Title: Backup Successful" \
                -H "Priority: low" \
                -H "Tags: white_check_mark,backup" \
                -d "Borg finished backing up to ${repo} successfully." \
                ${ntfyUrl}
            fi
          '';
      };
    })
  ];
}
