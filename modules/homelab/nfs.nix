# modules/homelab/nfs.nix
# NFS exports from the gateway to the PC (Minecraft world, personal files).
# The PC's own exports (pubdrive) are in hosts/nixos/filesystem.nix.
{ config, lib, ... }:
let
  homelab = config.homelab;
  nodes = homelab.nodes;
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

      # /srv/pubdrive 10.1.0.1(rw,sync,no_subtree_check,no_root_squash)
      # /srv/misc 10.1.0.1(rw,sync,no_subtree_check,no_root_squash)
      exports = ''
        ${homelab.drives.personal} ${nodes.pc.ipv4}(rw,sync,no_subtree_check,no_root_squash)
        ${homelab.drives.minecraft} ${nodes.pc.ipv4}(rw,sync,no_subtree_check,no_root_squash)
      '';
    };
    networking.firewall.allowedTCPPorts = ports;
    networking.firewall.allowedUDPPorts = ports;
  };
}
