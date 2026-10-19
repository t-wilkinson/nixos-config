# modules/homelab/phone-archive.nix
#
# Phone photos and files:
#   - Everything lands on the PC's HDD: Immich (the phone apps upload photos and videos) and
#     raw dumps in /mnt/storage/phones (adb pull, idevicebackup2, Syncthing).
#   - Weekly, the PC copies the oldest 200 GB of Immich originals (by capture date) to the Pi's
#     backup SSD. The PC pushes over SSH; on the Pi its key can only add files (rrsync -wo with
#     no delete and no overwrite), so a compromised PC can't wipe or overwrite the Pi's copy.
#
# Needs Immich's storage template set to {{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}
# (Administration -> Settings -> Storage Template), so originals sit in
# library/<user>/<year>/<yyyy-mm-dd>/ and sorting on that folder sorts by capture date.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  homelab = config.homelab;
  username = homelab.username;
  pi = homelab.nodes.pi;
  pc-storage = homelab.storage.disks.pc-storage;

  immichLibrary = "${pc-storage.shares.immich.path}/library";
  phonesDir = "${pc-storage.mountPoint}/phones"; # raw phone dumps on the PC's HDD
  piDir = "/srv/backup/phone-archive"; # on the Pi's backup SSD
  stateDir = "/var/lib/phone-archive"; # PC: SSH key, known_hosts, last file list
  limitBytes = 100 * 1000 * 1000 * 1000; # 200 GB

  # Public half of /var/lib/phone-archive/id_ed25519 on the PC (see the setup steps).
  # null = not set up yet: the Pi accepts no key for it.
  senderKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO/U50yCVsRpRDIFJCyRxDX2NJYZkDLleyiFf7AsCKaP phone-archive@pc";
  privateKeyFile = "/home/${username}/dev/t-wilkinson/personal/secrets/keys/phone-archive/id_ed25519";
in
lib.mkMerge [
  # PC: phone dumps, adb, and the weekly push of the oldest 200 GB
  (lib.mkIf (homelab.thisNode == "pc") {
    environment.systemPackages = [ pkgs.android-tools ]; # adb (libimobiledevice/ifuse: hosts/nixos)

    systemd.tmpfiles.rules = [
      "d ${phonesDir} 2770 ${username} storage-media - -"
      "d ${stateDir} 0700 root root - -"
    ];

    systemd.services.phone-archive = {
      description = "Copy the oldest 200 GB of phone photos to the Pi";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      unitConfig.RequiresMountsFor = [ immichLibrary ];
      path = with pkgs; [
        coreutils
        findutils
        gawk
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
        list=${stateDir}/files.txt

        # One line per original: <yyyy-mm-dd folder> <size> <path under the library>.
        # Sort oldest first, keep files while the running total stays under the limit.
        find ${immichLibrary} -type f -printf '%s\t%P\n' \
          | awk -F'\t' '{ n = split($2, p, "/"); if (n >= 4) print p[3] "\t" $1 "\t" $2 }' \
          | sort -t "$(printf '\t')" -k1,1 -k3,3 \
          | awk -F'\t' -v limit=${toString limitBytes} '{ total += $2; if (total <= limit) print $3 }' \
          > "$list"

        if [ ! -s "$list" ]; then
          echo "No files under ${immichLibrary}/<user>/<year>/<date>/. Is the storage template on?" >&2
          exit 1
        fi
        echo "Selected $(wc -l < "$list") files, oldest $(head -1 "$list"), newest $(tail -1 "$list")"

        rsync -rlt --ignore-existing --chmod=D0750,F0640 --files-from="$list" \
          -e "ssh -i ${privateKeyFile} -o UserKnownHostsFile=${stateDir}/known_hosts -o StrictHostKeyChecking=accept-new" \
          ${immichLibrary}/ phone-archive@${pi.ipv4}:./
      '';
    };

    systemd.timers.phone-archive = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true; # catch up after the PC was asleep
        RandomizedDelaySec = "1h";
      };
    };
  })

  # Pi: an add-only drop box on the backup SSD
  (lib.mkIf homelab.isGateway {
    users.groups.phone-archive = { };
    users.users.${username}.extraGroups = [ "phone-archive" ]; # browse the copy

    systemd.tmpfiles.rules = [ "d ${piDir} 0750 phone-archive phone-archive - -" ];

    users.users.phone-archive = {
      isSystemUser = true;
      group = "phone-archive";
      home = piDir;
      shell = pkgs.bashInteractive; # sshd runs the forced command through the login shell
      openssh.authorizedKeys.keys = lib.optional (
        senderKey != null
      ) ''restrict,command="${pkgs.rrsync}/bin/rrsync -wo -no-del -no-overwrite ${piDir}" ${senderKey}'';
    };
  })
]
