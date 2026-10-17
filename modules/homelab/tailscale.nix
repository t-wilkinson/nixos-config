# modules/homelab/tailscale.nix
# The gateway is the tailnet's subnet router for the homelab link, so tailnet devices reach
# the PC (10.1.0.1) and the gateway's Caddy/Blocky by their LAN addresses.
{ config, lib, ... }:
let
  homelab = config.homelab;
in
{
  config = lib.mkIf homelab.isGateway {
    services.tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "server";
      extraSetFlags = [ "--advertise-routes=${homelab.network.cidr}" ];
    };
  };
}
