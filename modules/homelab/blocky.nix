# modules/homelab/blocky.nix
# LAN DNS on the gateway node: *.home.lab, and private services' public names, point at it.
{ config, lib, ... }:
let
  homelab = config.homelab;
  net = homelab.network;
  gatewayIp = homelab.nodes.${homelab.gateway}.ipv4;

  privateServices = lib.filterAttrs (
    n: v: v.enable && v.expose && !v.isPublic && v.publicDomain != null
  ) homelab.services;
in
{
  config = lib.mkIf homelab.isGateway {
    services.resolved.enable = false; # Disable systemd-resolved to free port 53 for Blocky
    # services.resolved.extraConfig = "DNSStubListener=no"; # removed in 26.05; resolved is off anyway
    services.blocky = {
      enable = true;
      settings = {
        ports.dns = 53;
        # ports.http = 4000;
        upstreams.groups.default = [
          "https://1.1.1.1/dns-query" # Cloudflare
          "https://8.8.8.8/dns-query" # Google
        ];

        # Access your services via these domains
        customDNS = {
          customTTL = "1h";
          mapping = {
            # Map main domain and all subdomains to the gateway's direct IP
            "${net.domain}" = gatewayIp;
            "*.${net.domain}" = gatewayIp;
          }
          # Private services also answer on their public name, but only on the LAN/tailnet.
          # Public services keep resolving to Cloudflare (real certificate, e.g. Bitwarden mobile).
          // lib.mapAttrs' (n: v: lib.nameValuePair v.publicDomain gatewayIp) privateServices;
        };

        # Ad Blocking
        blocking = {
          # enable = true;
          blackLists = {
            ads = [ "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts" ];
          };
          clientGroupsBlock.default = [ "ads" ];
        };
      };
    };
  };
}
