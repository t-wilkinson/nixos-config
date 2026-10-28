# modules/homelab/fail2ban.nix
#
# fail2ban on the gateway (the only node reachable from the internet, through the tunnel), and
# what makes its bans work for tunnel traffic.
#
# Internet requests reach Caddy from cloudflared on 127.0.0.1, so fail2ban's usual iptables
# bans never match them. Jails that watch a public service use the `homelab-ban` action
# instead (homelab.bans.action), which blocks the IP in two places:
#   - Caddy: every site block imports /var/lib/homelab-bans/caddy/*.caddy, which answers 403
#     to banned addresses ({client_ip}, the real visitor). Works with no extra setup.
#   - Cloudflare's edge: an IP Access rule on the zone, so requests stop before the tunnel.
#     Needs homelab.network.cloudflareZoneId and the cloudflare_ban_token secret: an API
#     token with Zone > Firewall Services > Edit on that one zone. Only rules this action
#     created (note "homelab-ban (fail2ban)") are ever removed.
# `homelab-ntfy` sends a notification per ban, with the accounts that were tried.
#
# The dashboard (Security tile) lists bans and failed logins from security.json (written here,
# every minute and after every ban) and can unban: its button calls the webhook hook `unban`,
# which may only start homelab-unban@<jail>:<ip>.service (polkit), which checks the request
# and runs fail2ban-client as root.
#
# Repeat offenders get longer bans (bantime.increment, across jails, up to 4 weeks).
# By hand: sudo fail2ban-client status vaultwarden / set vaultwarden unbanip 1.2.3.4
{
  config,
  lib,
  pkgs,
  ...
}:
let
  homelab = config.homelab;
  net = homelab.network;
  services = homelab.services;
  files = homelab.statusFiles;
  cfg = homelab.bans;
  stateDir = "/var/lib/homelab-bans";

  cloudflare =
    net.cloudflareZoneId != null && homelab.lib.sopsHasKey homelab.lib.secretsFile "cloudflare_ban_token";
  ntfyHeader = config.sops.templates."ntfy-auth-header".path or null;
  notify = services.ntfy.runsHere && ntfyHeader != null;
  # The dashboard's hooks go to the wakeonlan service's webhook (dashboard.nix routes /hooks/*)
  hooks = services.wakeonlan.runsHere;

  tool = pkgs.writers.writePython3Bin "homelab-security" {
    # Long lines are fine; W503/W504 contradict each other
    flakeIgnore = [
      "E501"
      "W503"
      "W504"
    ];
  } (builtins.readFile ./scripts/homelab-security.py);

  toolConfig = pkgs.writeText "homelab-security.json" (
    builtins.toJSON {
      inherit stateDir;
      caddyUnit = "caddy.service";
      cloudflareZone = if cloudflare then net.cloudflareZoneId else null;
      cloudflareTokenFile = if cloudflare then config.sops.secrets.cloudflare_ban_token.path else null;
      banJails = cfg.jails;
      fail2banClient = "${config.services.fail2ban.package}/bin/fail2ban-client";
      fail2banDb = config.services.fail2ban.daemonSettings.Definition.dbfile;
      journalUnits = cfg.journalUnits;
      reportFile = "${files.dir}/security.json";
      reportGroup = files.group;
      reportUnit = "homelab-security-report.service";
      historyDays = 7;
      # Shown as "trusted" on the dashboard: fail2ban never bans these
      ignoreIP = [
        "127.0.0.1/8"
        "::1"
      ]
      ++ config.services.fail2ban.ignoreIP;
      ntfyUrl = "http://${services.ntfy.localEndpoint}/homelab";
      ntfyHeaderFile = ntfyHeader;
      dashboardUrl = "https://${services.dashboard.domain}/#security";
    }
  );
  run = "${lib.getExe tool} --config ${toolConfig}";

  unbanHook = pkgs.writeShellScript "homelab-unban-hook" ''
    # Runs as the webhook user: checks the shape of the request, then asks systemd (allowed
    # by the polkit rule below) to run the unban as root, which checks it again
    jail=$1 ip=$2
    [[ $jail =~ ^[A-Za-z0-9_.-]{1,64}$ ]] || { echo "invalid jail"; exit 1; }
    [[ $ip =~ ^[0-9A-Fa-f:.]{2,45}$ ]] || { echo "invalid address"; exit 1; }
    unit=$(${pkgs.systemd}/bin/systemd-escape --template=homelab-unban@.service "$jail:$ip")
    ${pkgs.systemd}/bin/systemctl start "$unit" 2>&1 && echo "Unbanned $ip ($jail)"
  '';
in
{
  options.homelab.bans = {
    enable = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      default = homelab.isGateway;
      description = "This node runs fail2ban and applies its bans to Caddy (the gateway).";
    };
    action = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = lib.concatStringsSep "\n          " (
        [ "homelab-ban[name=%(__name__)s]" ] ++ lib.optional notify "homelab-ntfy[name=%(__name__)s]"
      );
      description = "fail2ban `action` for jails that watch a public service: block in Caddy (and at Cloudflare), and notify.";
    };
    jails = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Jails that use homelab.bans.action (reconciled against fail2ban every few minutes).";
    };
    journalUnits = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Units whose failed logins (with the attempted user) the dashboard lists.";
    };
    caddyImport = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "${stateDir}/caddy/*.caddy";
      description = "Caddyfile import glob with the current bans (no file when nothing is banned).";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        warnings = lib.optional (!cloudflare) ''
          homelab: fail2ban bans are applied in Caddy only. To also block at Cloudflare's edge,
          set homelab.network.cloudflareZoneId and add cloudflare_ban_token (Zone > Firewall
          Services > Edit) to hosts/homelab/secrets.yaml.
        '';

        sops.secrets = lib.mkIf cloudflare {
          cloudflare_ban_token = {
            sopsFile = homelab.lib.secretsFile;
            owner = "root";
            mode = "0400";
          };
        };

        # Nextcloud
        environment.etc."fail2ban/filter.d/nextcloud.conf".text = pkgs.lib.mkDefault (
          pkgs.lib.mkAfter ''
            [Definition]
            _groupsre = (?:(?:,?\s*"\w+":(?:"[^"]+"|\w+))*)
            failregex = ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Login failed:
                        ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Trusted domain error.
            datepattern = ,?\s*"time"\s*:\s*"%%Y-%%m-%%d[T ]%%H:%%M:%%S(%%z)?"
          ''
        );

        environment.etc."fail2ban/action.d/homelab-ban.conf".text = ''
          [Definition]
          actionstart =
          actionstop =
          actioncheck =
          # Keep the bans applied while fail2ban restarts (it re-bans them on start);
          # `homelab-security reconcile` (timer) drops any that expired meanwhile
          actionflush = true
          actionban = ${run} ban <name> <ip>
          actionunban = ${run} unban <name> <ip>

          [Init]
          name = default
        '';
        environment.etc."fail2ban/action.d/homelab-ntfy.conf".text = ''
          [Definition]
          # Not again for bans restored when fail2ban restarts
          norestored = 1
          actionstart =
          actionstop =
          actioncheck =
          actionban = ${run} notify <name> <ip> <bantime> <failures>
          actionunban =

          [Init]
          name = default
        '';

        services.fail2ban = {
          enable = true;
          bantime = "24h";
          bantime-increment = {
            enable = true;
            maxtime = "4w";
            overalljails = true; # a ban in any jail counts towards the next one's length
          };
          # Never ban the homelab link or the tailnet (your own devices, and Caddy reports
          # them as the client for LAN requests)
          ignoreIP = [ net.cidr ] ++ net.privateRanges;
        };

        # The action runs inside fail2ban's sandbox (ProtectSystem=strict)
        systemd.services.fail2ban.serviceConfig.ReadWritePaths = [ stateDir ];
        systemd.tmpfiles.rules = [
          "d ${stateDir} 0755 root root - -"
          "d ${stateDir}/jails 0700 root root - -"
          "d ${stateDir}/caddy 0755 root root - -" # read by Caddy when it (re)loads
        ];

        systemd.services.homelab-bans-reconcile = {
          description = "Make Caddy's and Cloudflare's bans match fail2ban's";
          after = [ "fail2ban.service" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${run} reconcile";
          };
        };
        systemd.timers.homelab-bans-reconcile = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "3min";
            OnUnitActiveSec = "5min";
          };
        };
      }

      (lib.mkIf files.enable {
        systemd.services.homelab-security-report = {
          description = "Bans and failed logins for the dashboard";
          after = [ "fail2ban.service" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${run} report";
          };
        };
        systemd.timers.homelab-security-report = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "2min";
            OnUnitActiveSec = "1min";
          };
        };

        # %I: <jail>:<ip>, from the dashboard's unban button (checked again in the tool)
        systemd.services."homelab-unban@" = {
          description = "Unban %I (dashboard)";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${run} unban-request %I";
          };
        };
      })

      (lib.mkIf (files.enable && hooks) {
        services.webhook.hooks = {
          # POST {"jail": ..., "ip": ...} with header X-Homelab-Action: unban. The header can't
          # be sent cross-site without a CORS preflight, which webhook doesn't answer, so other
          # sites can't make your browser unban anything; the dashboard's login covers the rest.
          unban = {
            execute-command = "${unbanHook}";
            http-methods = [ "POST" ];
            pass-arguments-to-command = [
              {
                source = "payload";
                name = "jail";
              }
              {
                source = "payload";
                name = "ip";
              }
            ];
            trigger-rule.match = {
              type = "value";
              value = "unban";
              parameter = {
                source = "header";
                name = "X-Homelab-Action";
              };
            };
            trigger-rule-mismatch-http-response-code = 400;
            include-command-output-in-response = true;
            include-command-output-in-response-on-error = true;
          };
          # Fresh security.json before the dashboard shows it
          security-refresh = {
            execute-command = "${pkgs.systemd}/bin/systemctl";
            pass-arguments-to-command = [
              {
                source = "string";
                name = "start";
              }
              {
                source = "string";
                name = "homelab-security-report.service";
              }
            ];
            http-methods = [ "POST" ];
            trigger-rule.match = {
              type = "value";
              value = "refresh";
              parameter = {
                source = "header";
                name = "X-Homelab-Action";
              };
            };
            trigger-rule-mismatch-http-response-code = 400;
            include-command-output-in-response-on-error = true;
          };
        };

        security.polkit.extraConfig = ''
          // homelab: the webhook user may start the dashboard's unban and refresh units, nothing else
          polkit.addRule(function(action, subject) {
            if (action.id == "org.freedesktop.systemd1.manage-units" &&
                subject.user == "${config.services.webhook.user}" &&
                action.lookup("verb") == "start") {
              var unit = action.lookup("unit");
              if (unit == "homelab-security-report.service" ||
                  /^homelab-unban@[A-Za-z0-9_.:\\-]+\.service$/.test(unit)) {
                return polkit.Result.YES;
              }
            }
          });
        '';
      })
    ]
  );
}
