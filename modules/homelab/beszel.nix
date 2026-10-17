# modules/homelab/beszel.nix
# System metrics (CPU, memory, disks, temperatures, network, containers, GPU) with history and
# alerts. The hub (beszel.home.lab, behind the homelab login) runs on its host; every NixOS
# node runs an agent, which the hub reaches over SSH on port 45876.
#
# First run: open the hub, create its account with homelab.adminEmail (afterwards the homelab
# login signs you in, see TRUSTED_AUTH_HEADER), then click
# "Add system" and copy the public key into homelab.services.beszel.data.hubKey in the
# inventory. Agents stay off until that key is set. The systems themselves (one per node)
# come from the generated config.yml below, so they don't need adding by hand.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  homelab = config.homelab;
  nodes = homelab.nodes;
  cfg = homelab.services.beszel;
  me = nodes.${homelab.thisNode} or { };
  hubKey = cfg.data.hubKey or null;
  agentPort = 45876;
  agentHere = cfg.enable && hubKey != null && (me.ipv4 or null) != null;
  # Used as an attribute name below, which is evaluated even when agentHere is false
  iface = toString (me.lanInterface or "");

  # Nodes on the homelab link (the Mac isn't a NixOS node)
  agentNodes = lib.filterAttrs (n: node: node.ipv4 != null) nodes;
  systemsYml = (pkgs.formats.yaml { }).generate "beszel-config.yml" {
    systems = lib.mapAttrsToList (n: node: {
      name = node.name;
      host = if n == cfg.host then "127.0.0.1" else node.ipv4;
      port = agentPort;
      users = [ homelab.adminEmail ];
    }) agentNodes;
  };
in
{
  config = lib.mkMerge [
    (lib.mkIf cfg.runsHere {
      services.beszel.hub = {
        enable = true;
        host = "127.0.0.1";
        port = cfg.port;
        environment = {
          APP_URL = "https://${cfg.domain}";
          SHARE_ALL_SYSTEMS = "true"; # single-user homelab
          # Behind the homelab login (auth = true): Authelia's Remote-Email header logs you in
          # as the Beszel user with that email, so there's no second password after the first run
          TRUSTED_AUTH_HEADER = "Remote-Email";
        };
      };
      # Declarative systems: the hub syncs beszel_data/config.yml on start
      systemd.services.beszel-hub.serviceConfig.ExecStartPre = lib.mkAfter [
        "${pkgs.coreutils}/bin/install -D -m 0644 ${systemsYml} beszel_data/config.yml"
      ];
    })

    (lib.mkIf agentHere {
      services.beszel.agent = {
        enable = true;
        environment = {
          KEY = hubKey; # the hub's public key (not a secret)
          # The hub's own node is reached over loopback; the others on their homelab address
          LISTEN = if cfg.host == homelab.thisNode then "127.0.0.1:${toString agentPort}" else toString agentPort;
        }
        // lib.optionalAttrs (cfg.data ? extraFilesystems.${homelab.thisNode}) {
          EXTRA_FILESYSTEMS = cfg.data.extraFilesystems.${homelab.thisNode};
        };
      };
      # Only the hub (over the direct link) reaches other nodes' agents
      networking.firewall.interfaces.${iface}.allowedTCPPorts = lib.mkIf (
        cfg.host != homelab.thisNode
      ) [ agentPort ];
    })
  ];
}
