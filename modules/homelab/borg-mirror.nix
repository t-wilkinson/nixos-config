# modules/homelab/borg-mirror.nix
#
# Pi -> PC: a copy of the Pi's borg repo on the PC's storage drive (backups share,
# /mnt/storage/backups/pi-borg). The PC pulls, so it runs whenever the PC is awake
# (daily, catching up after sleep) and the Pi never needs to wake it.
#
# On the Pi, the PC's key may only run one command as root: rrsync, read-only, on the repo
# directory, inside `borg with-lock`. Holding borg's lock means the copy never sees a
# half-written repo; the nightly borg job waits for it (--lock-wait in ./borg.nix).
#
# Files the Pi removed or rewrote (borg compacts its segments) are moved to
# pi-borg-deleted/<date> instead of being deleted, and kept for keepDeletedDays: a wiped or
# damaged repo on the Pi can't take the PC's copy with it on the next run.
#
# The copy is still encrypted: restoring from it needs the repo passphrase (borg_pass), e.g.
#   borg list /mnt/storage/backups/pi-borg/homelab
{
  config,
  lib,
  pkgs,
  ...
}:
let
  hl = config.homelab;
  cfg = hl.services.borg-mirror;
  host = hl.nodes.${cfg.host}; # the PC
  source = hl.nodes.${cfg.data.source}; # the Pi

  # Same repo the borg job writes (./borg.nix), on the source node
  repo = "${hl.storage.shares.backup.path}/homelab";
  dest = "${hl.storage.shares.${cfg.data.share}.path}/pi-borg";
  stateDir = "/var/lib/borg-mirror";
  # Until jobs report to Gatus (./jobs.nix), failures notify ntfy directly
  canNotify = hl.services.ntfy.enable && config.sops.secrets ? ntfy_auth && !hl.jobReports.enable;
  ssh = "ssh -i ${host.backupKeyFile} -o UserKnownHostsFile=${stateDir}/known_hosts -o StrictHostKeyChecking=accept-new -o BatchMode=yes";
in
lib.mkIf cfg.enable (
  lib.mkMerge [
    {
      assertions = [
        {
          assertion = host.backupKey != null && host.backupKeyFile != null;
          message = "homelab.services.borg-mirror needs homelab.nodes.${cfg.host}.backupKey and backupKeyFile.";
        }
        {
          assertion = hl.services.borg.enable && hl.services.borg.host == cfg.data.source;
          message = "homelab.services.borg-mirror copies the borg repo, so borg must run on ${cfg.data.source}.";
        }
      ];

      # Reported to Gatus (./jobs.nix)
      homelab.jobs.borg-mirror = {
        name = "Backup mirror";
        node = cfg.host;
        unit = "borg-mirror";
        heartbeat = "96h"; # daily while the PC is awake
      };
    }

    # PC: pull
    (lib.mkIf cfg.runsHere {
      systemd.tmpfiles.rules = [ "d ${stateDir} 0700 root root - -" ];

      # Failures reach ntfy through Caddy (the PC trusts the homelab CA); the token is the
      # desktop subscriber's (hosts/nixos/default.nix)
      systemd.services.borg-mirror-failure-notify = lib.mkIf canNotify {
        description = "Notify that the borg mirror failed";
        serviceConfig.Type = "oneshot";
        script = ''
          ${pkgs.curl}/bin/curl -sS -H "Authorization: Bearer $(cat ${config.sops.secrets.ntfy_auth.path})" \
            -H "Title: Backup mirror failed on ${config.networking.hostName}" \
            -H "Priority: high" -H "Tags: warning,backup" \
            -d "Check 'journalctl -u borg-mirror' for details." \
            https://${hl.services.ntfy.domain}/homelab
        '';
      };

      systemd.services.borg-mirror = {
        description = "Copy the ${source.name}'s borg repo to this machine";
        unitConfig.OnFailure = lib.optional canNotify "borg-mirror-failure-notify.service";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        unitConfig.RequiresMountsFor = [ dest ];
        path = with pkgs; [
          coreutils
          findutils
          openssh
          rsync
        ];
        serviceConfig = {
          Type = "oneshot";
          Nice = 10;
          IOSchedulingClass = "idle";
        };
        script = ''
          set -euo pipefail
          today=$(date +%F)
          mkdir -p ${dest}/homelab ${dest}-deleted

          # The forced command on the Pi decides what is read; "." is the repo directory.
          # Refuse to mirror a repo that has lost its config file (wiped, or the drive missing):
          # --delete would otherwise empty the PC's copy too.
          if ! rsync --list-only -e "${ssh}" root@${source.ipv4}:config > /dev/null; then
            echo "The ${source.name}'s repo (${repo}) has no config file; not mirroring it." >&2
            exit 1
          fi

          # Skip borg's lock files: with-lock holds the lock during the copy, and a copied lock
          # would make the PC's copy look locked.
          rsync -a --delete --backup --backup-dir=${dest}-deleted/$today --info=stats1 \
            --exclude=/lock.exclusive --exclude=/lock.roster \
            -e "${ssh}" root@${source.ipv4}:. ${dest}/homelab/

          find ${dest}-deleted -mindepth 1 -maxdepth 1 -type d -mtime +${toString cfg.data.keepDeletedDays} \
            -print -exec rm -rf {} +
        '';
      };

      systemd.timers.borg-mirror = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*-*-* 06:00"; # after the Pi's 03:00 backup; on wake if the PC slept
          Persistent = true;
          RandomizedDelaySec = "15m";
        };
      };
    })

    # Pi: allow the read-only pull of the repo, nothing else
    (lib.mkIf (hl.thisNode == cfg.data.source && host.backupKey != null) {
      users.users.root.openssh.authorizedKeys.keys = [
        ''restrict,command="${config.services.borgbackup.package}/bin/borg with-lock --lock-wait 3600 ${repo} ${pkgs.rrsync}/bin/rrsync -ro ${repo}" ${host.backupKey}''
      ];
    })
  ]
)
