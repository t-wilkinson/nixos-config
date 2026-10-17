# modules/homelab/caddy.nix
# Reverse proxy on the gateway node: one site block per exposed service, answering on both
# its private and public names:
#   LAN/tailnet: x.home.lab and x.treywilkinson.com
#   internet:    x.treywilkinson.com, public services only (the tunnel only routes those)
# Services add lines to their own block with homelab.services.<n>.extraConfig / proxyConfig.
{ config, lib, ... }:
let
  homelab = config.homelab;
  services = homelab.services;
  net = homelab.network;

  # Deployed (anywhere in the homelab) and reachable through Caddy
  exposedServices = lib.filterAttrs (n: v: v.enable && v.expose) services;

  # LAN/tailnet client ranges. With trusted_proxies below, {client_ip} is the real visitor
  # (Cf-Connecting-Ip) for tunnel traffic, so internet requests never match these.
  privateRanges = homelab.lib.caddyPrivateRanges;

  mkCaddyProxy =
    name: service:
    let
      domains = [ service.domain ] ++ lib.optional (service.publicDomain != null) service.publicDomain;
      hostnames = lib.concatStringsSep ", " domains;

      proxyTo = endpoint: ''
        reverse_proxy ${endpoint} {
          header_up X-Real-IP {client_ip}
          header_up X-Forwarded-Port {http.request.port}
          ${service.proxyConfig}
        }
      '';

      # Private services: refuse anything that isn't LAN/tailnet (defense in depth; the tunnel
      # doesn't route their names anyway)
      lanOnly = lib.optionalString (!service.isPublic) ''
        @notLan not client_ip ${privateRanges}
        respond @notLan "Not found" 404
      '';
      # Login (Authelia) for services with auth = true; authBypass paths skip it
      authCheck = lib.optionalString service.auth ''
        ${lib.optionalString (service.authBypass != [ ]) "@needsAuth not path ${lib.concatStringsSep " " service.authBypass}"}
        forward_auth ${lib.optionalString (service.authBypass != [ ]) "@needsAuth "}${services.auth.localEndpoint} {
          uri /api/authz/forward-auth
          copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
        }
      '';
      # Everything below runs inside `route`, i.e. in the order written. (At the top level Caddy
      # sorts `handle` before `respond`, so access checks written as `respond` would never fire.)

      # service.paths = { "/notes" = "127.0.0.1:8090"; }: the prefix is passed on
      pathRoutes = lib.concatStrings (
        lib.mapAttrsToList (path: endpoint: ''
          redir ${path} ${path}/
          handle ${path}/* {
            ${proxyTo endpoint}
          }
        '') (service.paths or { })
      );
    in
    {
      name = hostnames;
      value = {
        extraConfig = ''
          @httpProto {
            header X-Forwarded-Proto http
          }
          redir @httpProto https://{host}{uri} permanent
          route {
            ${lanOnly}
            ${authCheck}
            ${service.extraConfig}
            ${pathRoutes}
            handle {
              ${proxyTo service.localEndpoint}
            }
          }
          tls internal
        '';
      };
    };
in
{
  config = lib.mkIf homelab.isGateway {
    services.caddy = {
      enable = true;
      # cloudflared connects from loopback; trust its Cf-Connecting-Ip header so {client_ip}
      # (and X-Forwarded-For / X-Real-IP sent to apps) is the real visitor, not 127.0.0.1.
      globalConfig = ''
        servers {
          trusted_proxies static 127.0.0.1/32 ::1/128
          client_ip_headers Cf-Connecting-Ip
        }
      '';
      virtualHosts = (lib.mapAttrs' mkCaddyProxy exposedServices) // {
        "${net.domain}".extraConfig = "redir https://${services.dashboard.domain}\ntls internal";
      };
    };
  };
}
