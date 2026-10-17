# modules/homelab/cloudflared.nix
# Cloudflare tunnel on the gateway node. Locally managed: the credentials JSON comes from
# `cloudflared tunnel create` (sops secret cloudflared_creds) and the ingress rules are
# generated here, one per public service, all pointing at Caddy.
{ config, lib, ... }:
let
  homelab = config.homelab;
  net = homelab.network;

  publicServices = lib.filterAttrs (
    n: v: v.enable && v.expose && v.isPublic && v.publicDomain != null
  ) homelab.services;

  mkIngressTunnel = name: service: {
    name = service.publicDomain;
    value = {
      service = "https://127.0.0.1:443";
      # if service.reverseProxy != null then
      #   "http://${service.reverseProxy}:${toString service.port}"
      # else
      #   "http://${service.localEndpoint}";
      originRequest = {
        # Keep the public Host header so apps build public links; Caddy's site block
        # answers on both names. TLS to Caddy on loopback uses its internal CA.
        # httpHostHeader = service.domain;
        originServerName = service.publicDomain;
        noTLSVerify = true;
      };
    };
  };
in
{
  config = lib.mkIf (homelab.isGateway && net.cloudflareTunnelId != null) {
    services.cloudflared = {
      enable = true;
      tunnels = {
        "${net.cloudflareTunnelId}" = {
          # creds generated with 'cloudflared tunnel create'
          credentialsFile = config.sops.secrets."cloudflared_creds".path;
          default = "http_status:404"; # Default Rule: Hide everything else!
          ingress =
            # Only enabled public services; everything else falls through to the 404 default
            (lib.mapAttrs' mkIngressTunnel publicServices) // {
              # "${services.mc-server.publicDomain}" = {
              #   service = "tcp://127.0.0.1:${toString services.mc-server.port}";
              #   originRequest = {
              #     httpHostHeader = services.mc-server.domain;
              #   };
              # };
            };

        };
      };
    };
    # Pin the metrics/readiness endpoint (otherwise the first free port in 20241-20245);
    # Gatus and homelab-status read /ready here
    systemd.services."cloudflared-tunnel-${net.cloudflareTunnelId}".environment.TUNNEL_METRICS =
      "127.0.0.1:20241";
  };
}
