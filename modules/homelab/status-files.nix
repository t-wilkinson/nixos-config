# modules/homelab/status-files.nix
#
# Status JSON for the dashboard: small jobs on the gateway write files here (backups.json from
# ./backup-report.nix, security.json from ./fail2ban.nix) and the dashboard only displays them.
# Caddy serves the directory twice:
#   https://dash.home.lab/status/<file>   for the dashboard's own scripts (behind the login)
#   http://127.0.0.1:<statusPort>/<file>  for Homepage's widgets, which fetch server-side
#                                         (loopback only: the homelab link and tailnet are
#                                         trusted interfaces on the Pi, so `bind` matters)
{ config, lib, ... }:
let
  hl = config.homelab;
  cfg = hl.statusFiles;
  dashboard = hl.services.dashboard;
in
{
  options.homelab.statusFiles = {
    dir = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "/var/lib/homelab-dash";
      description = "Where status JSON for the dashboard is written (root:caddy, 0640 files).";
    };
    group = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "caddy";
      description = "Group that may read the status files (Caddy serves them).";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = dashboard.data.statusPort or 8095;
      description = "Loopback port Caddy serves the status files on, for Homepage's widgets.";
    };
    url = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "http://127.0.0.1:${toString cfg.port}";
      description = "Base URL of the status files for widgets (as seen from the gateway).";
    };
    enable = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      default = hl.isGateway && dashboard.enable && dashboard.host == hl.gateway;
      description = "This node keeps the status files (the gateway, which runs Caddy and the dashboard).";
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = !dashboard.enable || dashboard.host == hl.gateway;
          message = "homelab: the dashboard reads status files the gateway serves, so it must run on ${hl.gateway}.";
        }
      ];

      homelab.services.dashboard.extraConfig = ''
        # Status JSON (modules/homelab/status-files.nix)
        handle_path /status/* {
          root * ${cfg.dir}
          header Cache-Control "no-store"
          file_server
        }
      '';
    }

    (lib.mkIf cfg.enable {
      systemd.tmpfiles.rules = [ "d ${cfg.dir} 0750 root ${cfg.group} - -" ];

      services.caddy.virtualHosts."http://127.0.0.1:${toString cfg.port}".extraConfig = ''
        bind 127.0.0.1
        root * ${cfg.dir}
        header Cache-Control "no-store"
        file_server
      '';
    })
  ];
}
