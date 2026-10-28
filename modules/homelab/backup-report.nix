# modules/homelab/backup-report.nix
#
# backups.json for the dashboard, on the node that holds the borg repos (the Pi):
#   - per repo: newest archive (time, duration, data added), repo size on disk, archive count
#   - per job (./jobs.nix): last result in Gatus, failures in the last 7 days
# Every 30 minutes, and right after a local job finishes. The PC's jobs report to Gatus, so
# they show up at the next run.
#
# Each repo is read by its own small unit running as the repo's user: borg-pc's append-only
# repo must never get root-owned lock or cache files (see ./borg-pc.nix). Those units leave
# `borg info` / `borg list` JSON in /run/backup-report-<repo>/ for the collector.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  hl = config.homelab;
  files = hl.statusFiles;
  borgPkg = config.services.borgbackup.package;
  borgPc = hl.services.borg-pc;

  repos =
    lib.optional hl.services.borg.runsHere {
      id = "homelab";
      name = "Pi";
      path = config.services.borgbackup.jobs.homelab.repo;
      user = "root";
      baseDir = null; # root's ~/.cache/borg, shared with the backup job
      maxAgeHours = 26;
    }
    ++ lib.optional (borgPc.enable && borgPc.data.target == hl.thisNode) {
      id = "pc";
      name = "PC";
      path = hl.storage.shares.${borgPc.data.share}.path;
      user = "borg-pc";
      baseDir = "/var/lib/borg-pc-prune"; # the cache borg-pc-prune and borg-pc-check use
      # The PC backs up when it's awake: a few days without one is worth a look, not an alarm
      maxAgeHours = 72;
    };

  enabled = repos != [ ] && files.enable;

  reportConfig = pkgs.writeText "backup-report.json" (
    builtins.toJSON {
      out = "${files.dir}/backups.json";
      inherit (files) group;
      gatus = if hl.services.gatus.runsHere then "http://${hl.services.gatus.localEndpoint}" else null;
      repos = map (r: {
        inherit (r)
          id
          name
          path
          maxAgeHours
          ;
        dir = "/run/backup-report-${r.id}";
      }) repos;
      jobs = lib.optionals hl.jobReports.enable (
        lib.mapAttrsToList (id: j: {
          inherit id;
          inherit (j)
            name
            node
            key
            heartbeat
            ;
        }) hl.jobs
      );
    }
  );

  collector = pkgs.writers.writePython3Bin "backup-report" {
    # Long lines are fine; W503/W504 contradict each other
    flakeIgnore = [
      "E501"
      "W503"
      "W504"
    ];
  } (builtins.readFile ./scripts/backup-report.py);

  repoUnit = r: {
    description = "Read the ${r.name} borg repo for the dashboard";
    serviceConfig = {
      Type = "oneshot";
      User = r.user;
      Group = if r.user == "root" then "root" else r.user;
      LoadCredential = "pass:${config.sops.secrets.borg_pass.path}";
      RuntimeDirectory = "backup-report-${r.id}";
      RuntimeDirectoryPreserve = true; # the collector reads it after this exits
      Nice = 10;
      IOSchedulingClass = "idle";
    }
    // lib.optionalAttrs (r.baseDir != null) {
      StateDirectory = lib.removePrefix "/var/lib/" r.baseDir;
    };
    environment = lib.optionalAttrs (r.baseDir != null) { BORG_BASE_DIR = r.baseDir; };
    path = [
      borgPkg
      pkgs.coreutils
    ];
    unitConfig.ConditionPathExists = "${r.path}/config"; # no repo yet: nothing to read
    script = ''
      export BORG_PASSCOMMAND="cat $CREDENTIALS_DIRECTORY/pass"
      dir=$RUNTIME_DIRECTORY
      # A running backup or the PC's copy of the repo holds the lock; wait a little, then
      # leave the previous numbers (the collector reports the error).
      if borg info --json --last 1 --lock-wait 120 ${lib.escapeShellArg r.path} > "$dir/info.json.tmp" 2> "$dir/stderr" &&
         borg list --json --lock-wait 120 ${lib.escapeShellArg r.path} > "$dir/list.json.tmp" 2>> "$dir/stderr"; then
        mv "$dir/info.json.tmp" "$dir/info.json"
        mv "$dir/list.json.tmp" "$dir/list.json"
        rm -f "$dir/error"
      else
        tail -n 5 "$dir/stderr" > "$dir/error"
        rm -f "$dir"/*.tmp
      fi
    '';
  };
in
{
  config = lib.mkIf enabled {
    systemd.services =
      lib.listToAttrs (map (r: lib.nameValuePair "backup-report-${r.id}" (repoUnit r)) repos)
      // {
        backup-report = {
          description = "Backup status for the dashboard";
          wants = map (r: "backup-report-${r.id}.service") repos;
          after = map (r: "backup-report-${r.id}.service") repos ++ [ "gatus.service" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${lib.getExe collector} --config ${reportConfig}";
          };
        };
      }
      # Refresh as soon as a local job finishes (jobs.nix registers them)
      // lib.mapAttrs' (
        n: j:
        lib.nameValuePair j.unit {
          serviceConfig.ExecStopPost = [ "-${pkgs.systemd}/bin/systemctl start --no-block backup-report.service" ];
        }
      ) (lib.filterAttrs (n: j: j.node == hl.thisNode) hl.jobs);

    systemd.timers.backup-report = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "3min";
        OnUnitActiveSec = "30min";
      };
    };
  };
}
