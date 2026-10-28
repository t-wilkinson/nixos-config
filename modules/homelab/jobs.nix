# modules/homelab/jobs.nix
#
# Scheduled jobs (backups, repo checks, pruning) report every run to Gatus as "external
# endpoints": each run pushes success or failure, and Gatus alerts (ntfy) on a failure or when a
# job stops reporting for longer than its heartbeat. The PC's jobs report too, even though its
# systemd state is invisible from the Pi.
#
# Modules register their jobs here, unconditionally, so every node (and Gatus on the Pi) sees
# the whole list:
#   homelab.jobs.borg-homelab = { name = "Pi backup"; node = "pi"; unit = "borgbackup-job-homelab"; heartbeat = "26h"; };
#
# Needs the gatus_push_token secret (`sops hosts/homelab/secrets.yaml`, any random string, e.g.
# `openssl rand -hex 32`). Until it exists, jobs don't report and keep their own ntfy failure
# notifications (homelab.jobReports.enable is false).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  hl = config.homelab;
  gatus = hl.services.gatus;
  enabled = config.homelab.jobReports.enable;
  localJobs = lib.filterAttrs (n: j: j.node == hl.thisNode) hl.jobs;

  # Gatus listens on loopback; other nodes go through Caddy (status.home.lab, push path exempt
  # from the login, see gatus.nix)
  gatusUrl =
    if gatus.runsHere then "http://${gatus.localEndpoint}" else "https://${toString gatus.domain}";

  push = pkgs.writeShellApplication {
    name = "homelab-job-push";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      systemd
    ];
    text = ''
      # ExecStopPost of a job: report this run to Gatus. systemd sets SERVICE_RESULT,
      # EXIT_CODE and EXIT_STATUS for ExecStopPost commands.
      key=$1 unit=$2
      result=''${SERVICE_RESULT:-unknown}
      if [ "$result" = success ]; then
        success=true err=""
      else
        success=false
        err="$result (''${EXIT_CODE:-?} ''${EXIT_STATUS:-?}) on $(hostname): journalctl -u $unit"
      fi

      args=()
      start=$(systemctl show -P ExecMainStartTimestampMonotonic "$unit" 2> /dev/null || echo 0)
      end=$(systemctl show -P ExecMainExitTimestampMonotonic "$unit" 2> /dev/null || echo 0)
      if [ "''${start:-0}" -gt 0 ] && [ "''${end:-0}" -ge "$start" ]; then
        args+=(--data-urlencode "duration=$(((end - start) / 1000000))s")
      fi

      # -G puts the data in the query string; -X POST keeps the method
      curl -fsS -o /dev/null --max-time 20 --retry 3 --retry-delay 10 --retry-all-errors \
        -X POST -G -H @${config.sops.templates."gatus-push-header".path} \
        --data-urlencode "success=$success" --data-urlencode "error=$err" "''${args[@]}" \
        "${gatusUrl}/api/v1/endpoints/$key/external" \
        || echo "could not report $unit to Gatus" >&2
    '';
  };
in
{
  options.homelab = {
    jobs = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                description = "Shown in Gatus and on the dashboard. Letters, digits and spaces (it becomes the Gatus key).";
              };
              node = lib.mkOption {
                type = lib.types.str;
                description = "Node (homelab.nodes) whose systemd runs the job.";
              };
              unit = lib.mkOption {
                type = lib.types.str;
                default = name;
                description = "The job's systemd service, without .service.";
              };
              heartbeat = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                example = "26h";
                description = "Alert when no run has reported for this long (Go duration: h, m, s; no d).";
              };
              key = lib.mkOption {
                type = lib.types.str;
                readOnly = true;
                # Gatus's key: <group>_<name>, lowercased, with " /_.,#+&" turned into "-"
                default =
                  let
                    sanitize =
                      s:
                      lib.replaceStrings [ " " "/" "_" "." "," "#" "+" "&" ] [ "-" "-" "-" "-" "-" "-" "-" "-" ] (
                        lib.toLower (lib.trim s)
                      );
                  in
                  "${sanitize config.homelab.jobReports.group}_${sanitize config.homelab.jobs.${name}.name}";
              };
            };
          }
        )
      );
      default = { };
      description = "Scheduled jobs that report each run to Gatus (./jobs.nix).";
    };

    jobReports = {
      enable = lib.mkOption {
        type = lib.types.bool;
        readOnly = true;
        default = gatus.enable && hl.lib.sopsHasKey hl.lib.secretsFile "gatus_push_token";
        description = "Jobs report to Gatus (Gatus is enabled and the gatus_push_token secret exists).";
      };
      group = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        default = "Jobs";
        description = "Gatus group of the job endpoints.";
      };
    };
  };

  config = lib.mkMerge [
    {
      warnings = lib.optional (gatus.enable && !enabled && localJobs != { }) ''
        homelab: backup jobs don't report to Gatus yet: add gatus_push_token to
        hosts/homelab/secrets.yaml (`openssl rand -hex 32`, then `sops hosts/homelab/secrets.yaml`).
      '';
    }

    (lib.mkIf (enabled && (localJobs != { } || gatus.runsHere)) {
      sops.secrets.gatus_push_token = {
        sopsFile = hl.lib.secretsFile;
        owner = "root";
        mode = "0400";
      };
      sops.templates."gatus-push-header".content = ''
        Authorization: Bearer ${config.sops.placeholder.gatus_push_token}
      '';
    })

    (lib.mkIf enabled {
      # "-": a failed report never fails the job; "+": full privileges, to read the token even
      # when the job runs as another user (borg-pc-prune)
      systemd.services = lib.mapAttrs' (
        n: j:
        lib.nameValuePair j.unit {
          serviceConfig.ExecStopPost = [ "-+${lib.getExe push} ${j.key} ${j.unit}.service" ];
        }
      ) localJobs;
    })
  ];
}
