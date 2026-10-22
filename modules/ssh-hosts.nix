# modules/ssh-hosts.nix
#
# `ssh pi`, `ssh pc` (and scp, rsync, ...) from any machine, generated from the homelab
# nodes in hosts/inventory.nix. Each name goes straight to the node's address on the homelab
# link (10.1.0.x), so it doesn't depend on DNS:
#   on the PC        over the direct ethernet link
#   on the Mac/away  through the Pi's Tailscale subnet route (like every *.home.lab name)
# HostKeyAlias keeps one known_hosts entry per node, whatever name or address you used.
#
# System-wide (/etc/ssh/ssh_config); ~/.ssh/config is still read first and can override.
{
  lib,
  username,
  ...
}:
let
  homelab = (import ../hosts/inventory.nix { inherit username; }).homelab;
  nodes = lib.filterAttrs (n: v: (v.ipv4 or null) != null) homelab.nodes;

  hostBlock = name: node: ''
    Host ${lib.concatStringsSep " " (lib.unique [ name (node.hostname or name) ])}
      HostName ${node.ipv4}
      HostKeyAlias ${name}
      User ${username}
      # Fail in seconds, not minutes, when the node is off or unreachable
      ConnectTimeout 5
  '';
in
{
  programs.ssh.extraConfig = lib.concatStrings (lib.mapAttrsToList hostBlock nodes);
}
