# modules/homelab/nfs.nix
# NFS server ports and firewall on the gateway. What is exported to whom (personal files and the
# Minecraft world to the PC, the PC's pubdrive to the Pi) comes from homelab.storage
# (./storage.nix, shares with `nfs` set in hosts/inventory.nix).
{ config, lib, ... }:
let
  homelab = config.homelab;
  # Fixed ports for firewall stability
  ports = [
    111
    2049
    4000
    4001
    4002
  ];
in
{
  config = lib.mkIf homelab.isGateway {
    services.nfs.server = {
      enable = true;
      lockdPort = 4001;
      mountdPort = 4002;
      statdPort = 4000;
    };
    networking.firewall.allowedTCPPorts = ports;
    networking.firewall.allowedUDPPorts = ports;
  };
}
