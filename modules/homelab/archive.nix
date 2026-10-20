# modules/homelab/archive.nix
#
# PC -> Pi: a second copy of the PC's oldest files, on the Pi's drive.
#
# Each set (homelab.services.archive.data.sets in hosts/inventory.nix) names its sources (share
# names or absolute paths on the PC), filters, an order and a size limit. Daily, the PC picks
# each set's files with ./archive-select.py and pushes the new ones to the Pi's archive share
# (/srv/backup/pc-archive/<set>/<original path>).
#
# On the Pi the PC's key can only add files (rrsync -wo -no-del -no-overwrite), so a
# compromised PC can neither delete nor overwrite what is already there. In turn:
#   - files stay on the Pi after they leave the window (when older ones are added, or a file
#     is renamed), so the copy can grow past the limits over time;
#   - a file edited on the PC isn't updated on the Pi;
#   - sets with keepDays (the Immich database dumps) are pruned by the Pi itself.
#
# Set keys:
#   sources            share names (homelab.storage) or absolute paths on the PC
#   limit              "100G" (GiB), "500M", ...
#   order              "oldest" (default) or "newest"
#   extensions         only files with these extensions (case-insensitive); default: all
#   excludeExtensions  never files with these extensions
#   include / exclude  globs matched against "<source dir name>/<path inside it>",
#                      e.g. "pubdrive/*", "data/*/files/*"
#   keepDays           the Pi deletes this set's copies older than this many days
{
  config,
  lib,
  pkgs,
  ...
}:
let
  hl = config.homelab;
  cfg = hl.services.archive;
  shares = hl.storage.shares;

  target = hl.nodes.${cfg.data.target};
  host = hl.nodes.${cfg.host};
  piDir = shares.${cfg.data.share}.path; # on the target

  resolve = src: if lib.hasPrefix "/" src then src else shares.${src}.path;
  defaultExclude = [
    "*/.*" # hidden files and folders (.stfolder, .thumbnails, ...)
    "*/@eaDir/*"
    "*.part"
    "*/appdata_*" # Nextcloud's previews and caches
    "*/files_trashbin/*"
    "*/files_versions/*"
  ];
  sets = lib.mapAttrs (
    n: s:
    s
    // {
      sources = map resolve s.sources;
      exclude = (s.exclude or [ ]) ++ defaultExclude;
    }
  ) cfg.data.sets;
  configFile = pkgs.writeText "archive-sets.json" (builtins.toJSON { inherit sets; });

  stateDir = "/var/lib/homelab-archive"; # PC: known_hosts and the last file lists
  ssh = "ssh -i ${host.backupKeyFile} -o UserKnownHostsFile=${stateDir}/known_hosts -o StrictHostKeyChecking=accept-new -o BatchMode=yes";

  prunedSets = lib.filterAttrs (n: s: s ? keepDays) cfg.data.sets;
in
lib.mkIf cfg.enable (
  lib.mkMerge [
    {
      assertions = [
        {
          assertion = host.backupKey != null && host.backupKeyFile != null;
          message = "homelab.services.archive needs homelab.nodes.${cfg.host}.backupKey and backupKeyFile.";
        }
        {
          assertion = shares ? ${cfg.data.share} && shares.${cfg.data.share}.node == cfg.data.target;
          message = "homelab.services.archive: share ${cfg.data.share} must be on ${cfg.data.target}.";
        }
      ];
    }

    # PC: pick and push
    (lib.mkIf cfg.runsHere {
      systemd.tmpfiles.rules = [ "d ${stateDir} 0700 root root - -" ];

      systemd.services.homelab-archive = {
        description = "Copy the oldest PC files to the ${target.name}";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        unitConfig.RequiresMountsFor = lib.unique (
          lib.concatMap (s: s.sources) (lib.attrValues sets)
        );
        path = with pkgs; [
          coreutils
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
          ${pkgs.python3}/bin/python3 -I ${./archive-select.py} ${configFile} ${stateDir}/lists

          ${lib.concatMapStrings (name: ''
            echo "Sending ${name}..."
            rsync -lt --from0 --files-from=${stateDir}/lists/${name}.list \
              --ignore-existing --chmod=D0750,F0640 --info=stats1 \
              -e "${ssh}" / archive@${target.ipv4}:./${name}/
          '') (lib.attrNames sets)}
        '';
      };

      systemd.timers.homelab-archive = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true; # catch up after the PC was asleep
          RandomizedDelaySec = "1h";
        };
      };
    })

    # Pi: an add-only drop box
    (lib.mkIf (hl.thisNode == cfg.data.target) {
      users.groups.archive = { };
      users.users.${hl.username}.extraGroups = [ "archive" ]; # browse the copy
      users.users.archive = {
        isSystemUser = true;
        group = "archive";
        home = piDir;
        shell = pkgs.bashInteractive; # sshd runs the forced command through the login shell
        openssh.authorizedKeys.keys = lib.optional (host.backupKey != null)
          ''restrict,command="${pkgs.rrsync}/bin/rrsync -wo -no-del -no-overwrite ${piDir}" ${host.backupKey}'';
      };

      systemd.services.homelab-archive-prune = lib.mkIf (prunedSets != { }) {
        description = "Delete old copies from the PC archive";
        serviceConfig.Type = "oneshot";
        script = lib.concatMapStrings (name: ''
          if [ -d ${piDir}/${name} ]; then
            ${pkgs.findutils}/bin/find ${piDir}/${name} -type f -mtime +${toString prunedSets.${name}.keepDays} -print -delete
          fi
        '') (lib.attrNames prunedSets);
        startAt = "daily";
      };
    })
  ]
)
