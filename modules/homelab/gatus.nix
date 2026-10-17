# modules/homelab/gatus.nix
# Status page + uptime history (status.home.lab, behind the homelab login), with ntfy alerts
# to the "homelab" topic. Every check is generated from the inventory:
#   - each monitored service, probed directly on its host (not through Caddy/Authelia)
#   - each public service through Cloudflare (tunnel + certificate)
#   - LAN DNS (Blocky), the Cloudflare tunnel's readiness, and every node by ping
# Services and nodes that sleep (wakeOnLan = true, the PC) are shown but never alert.
# homelab-status still covers what Gatus can't see: units, disks, NFS, backups.
{
  config,
  lib,
  ...
}:
let
  homelab = config.homelab;
  services = homelab.services;
  nodes = homelab.nodes;
  net = homelab.network;
  cfg = services.gatus;

  sleeps = host: nodes.${host}.wakeOnLan or false;
  alertsFor = host: lib.optional (!sleeps host) { type = "ntfy"; };

  probed = lib.filterAttrs (
    n: s: s.enable && s.monitor && s.port != null && n != "gatus" && n != "borg"
  ) services;
  public = lib.filterAttrs (
    n: s: s.enable && s.monitor && s.expose && s.isPublic && s.publicDomain != null
  ) services;

  serviceEndpoints = lib.mapAttrsToList (n: s: {
    name = s.name;
    group = nodes.${s.host}.name;
    # Straight to the service on its host: tests the service, not the login in front of it
    url = "http://${s.localEndpoint}/";
    interval = "1m";
    conditions = [ "[STATUS] < 500" ];
    alerts = alertsFor s.host;
  }) probed;

  publicEndpoints = lib.mapAttrsToList (n: s: {
    name = s.publicDomain;
    group = "Public (Cloudflare)";
    url = "https://${s.publicDomain}/";
    interval = "5m";
    conditions = [
      "[STATUS] < 500"
      "[CERTIFICATE_EXPIRATION] > 168h"
    ];
    alerts = alertsFor s.host;
  }) public;

  gatewayIp = nodes.${homelab.gateway}.ipv4;
  infraEndpoints = [
    {
      name = "LAN DNS (Blocky)";
      group = "Infrastructure";
      url = gatewayIp;
      dns = {
        query-name = services.dashboard.domain;
        query-type = "A";
      };
      interval = "1m";
      conditions = [
        "[DNS_RCODE] == NOERROR"
        "[BODY] == ${gatewayIp}"
      ];
      alerts = alertsFor homelab.gateway;
    }
  ]
  ++ lib.optional config.services.cloudflared.enable {
    name = "Cloudflare tunnel";
    group = "Infrastructure";
    url = "http://127.0.0.1:20241/ready"; # TUNNEL_METRICS, cloudflared.nix
    interval = "1m";
    conditions = [
      "[STATUS] == 200"
      "[BODY].readyConnections > 0"
    ];
    alerts = alertsFor homelab.gateway;
  }
  ++ lib.mapAttrsToList (n: node: {
    name = node.name;
    group = "Nodes";
    url = "icmp://${node.ipv4}";
    interval = "1m";
    conditions = [ "[CONNECTED] == true" ];
    alerts = alertsFor n;
  }) (lib.filterAttrs (n: node: node.ipv4 != null && n != homelab.thisNode) nodes);
in
{
  config = lib.mkIf cfg.runsHere {
    # ntfy token for alerts (Gatus substitutes ${NTFY_TOKEN} from the environment)
    sops.templates."gatus-env" = {
      content = "NTFY_TOKEN=${config.sops.placeholder.ntfy_auth}";
      restartUnits = [ "gatus.service" ];
    };

    services.gatus = {
      enable = true;
      environmentFile = config.sops.templates."gatus-env".path;
      settings = {
        web = {
          address = "127.0.0.1";
          port = cfg.port;
        };
        ui = {
          title = "Homelab status";
          header = "Homelab status";
        };
        storage = {
          type = "sqlite";
          path = "/var/lib/gatus/data.db";
        };
        alerting.ntfy = {
          url = "http://${services.ntfy.localEndpoint}";
          topic = "homelab";
          token = "\${NTFY_TOKEN}";
          priority = 4;
          default-alert = {
            failure-threshold = 3;
            success-threshold = 2;
            send-on-resolved = true;
          };
        };
        endpoints = serviceEndpoints ++ publicEndpoints ++ infraEndpoints;
      };
    };
  };
}
