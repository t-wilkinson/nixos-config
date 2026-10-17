# modules/homelab/wakeonlan.nix
# Wake and sleep buttons for nodes with wakeOnLan = true in the inventory (the PC).
#   wake:  the wakeonlan service's host (the Pi) runs webhook hook wake-<node>, which sends a
#          magic packet to the link's broadcast address (10.1.0.3). Not to the node's IP: once
#          the PC sleeps its ARP entry expires, the kernel can't resolve 10.1.0.1 and the
#          packet is never sent.
#   sleep: the node itself runs webhook hook sleep-<node> (systemctl suspend, allowed by polkit),
#          reachable only on its homelab interface.
# The dashboard's site block routes /hooks/sleep-<node> to the node and /hooks/* to the Pi.
{
  lib,
  config,
  pkgs,
  ...
}:
let
  homelab = config.homelab;
  cfg = homelab.services.wakeonlan;
  net = homelab.network;
  wolNodes = lib.filterAttrs (n: node: node.wakeOnLan) homelab.nodes;
  me = homelab.nodes.${homelab.thisNode} or { };
  sleepHere = cfg.enable && (me.wakeOnLan or false);
  # Used as an attribute name below, which is evaluated even when sleepHere is false
  iface = toString (me.lanInterface or "");

  wakeonlanScript = node: ''
        exec ${pkgs.python3}/bin/python3 -c '
    import subprocess
    from http.server import HTTPServer, BaseHTTPRequestHandler

    # Broadcast to the subnet or interface:
    CMD = ["wakeonlan", "-i", "${node.ipv4}", "${node.mac}"]

    class Handler(BaseHTTPRequestHandler):
      def do_GET(self):
          subprocess.run(CMD)
          self.send_response(200)
          self.send_header("Content-type", "text/plain")
          self.end_headers()
          self.wfile.write(b"WOL packet sent")

      def log_message(self, format, *args):
          pass

    HTTPServer(("127.0.0.1", ${toString cfg.port}), Handler).serve_forever()
    '
  '';
in
{
  config = lib.mkMerge [
    {
      assertions = lib.mapAttrsToList (n: node: {
        assertion = node.mac != null && node.ipv4 != null && node.lanInterface != null;
        message = "homelab.nodes.${n}.wakeOnLan needs mac, ipv4 and lanInterface.";
      }) wolNodes;

      # Sleep routes go to the node itself; they must come before the dashboard's /hooks/* route
      homelab.services.dashboard.extraConfig = lib.mkIf cfg.enable (
        lib.mkBefore (
          lib.concatStrings (
            lib.mapAttrsToList (n: node: ''
              handle /hooks/sleep-${n} {
                reverse_proxy ${node.ipv4}:${toString cfg.port}
              }
            '') wolNodes
          )
        )
      );
    }

    # The Pi: wake hooks
    (lib.mkIf cfg.runsHere {
      services.webhook = {
        enable = true;
        ip = "127.0.0.1"; # only Caddy (the dashboard's /hooks/*); end0 and tailscale0 are trusted interfaces
        port = cfg.port;
        hooks = lib.mapAttrs' (
          n: node:
          lib.nameValuePair "wake-${n}" {
            execute-command = "${pkgs.wakeonlan}/bin/wakeonlan";
            command-working-directory = "/tmp";
            pass-arguments-to-command =
              map
                (a: {
                  source = "string";
                  name = a;
                })
                [
                  "-i"
                  net.broadcast
                  "-p"
                  "9"
                  node.mac
                ];
            include-command-output-in-response = true;
          }
        ) wolNodes;
      };
      # systemd.services.wol-trigger = {
      #   description = "Wake-on-LAN Trigger Endpoint";
      #   wantedBy = [ "multi-user.target" ];
      #   after = [ "network.target" ];
      #   path = [ pkgs.wakeonlan ];
      #   serviceConfig = {
      #     ExecStart = pkgs.writeShellScript "wol-server" (wakeonlanScript homelab.nodes.pc);
      #     Restart = "on-failure";
      #     DynamicUser = true;
      #   };
      # };
    })

    # The sleeping node (PC): arm WoL on its homelab NIC and serve the sleep hook
    (lib.mkIf sleepHere {
      # Applied by udev when the NIC appears; the NetworkManager profile must agree, or NM may
      # reset it (see the wired-homelab profile in hosts/nixos/networking.nix)
      networking.interfaces.${iface}.wakeOnLan.enable = true;

      services.webhook = {
        enable = true;
        port = cfg.port;
        hooks."sleep-${homelab.thisNode}" = {
          execute-command = "${pkgs.systemd}/bin/systemctl";
          pass-arguments-to-command = [
            {
              source = "string";
              name = "suspend";
            }
          ];
          # Empty on success; "Operation inhibited ..." etc. on failure
          include-command-output-in-response = true;
          include-command-output-in-response-on-error = true;
        };
      };
      # Listens on all addresses (the link may come up after the service), but only the homelab
      # interface lets it through: the Pi's Caddy, and tailnet clients via the Pi's subnet route.
      networking.firewall.interfaces.${iface}.allowedTCPPorts = [ cfg.port ];

      security.polkit.extraConfig = ''
        // homelab: the webhook user may suspend this machine (dashboard sleep button)
        polkit.addRule(function(action, subject) {
          if ((action.id == "org.freedesktop.login1.suspend" ||
               action.id == "org.freedesktop.login1.suspend-multiple-sessions") &&
              subject.user == "${config.services.webhook.user}") {
            return polkit.Result.YES;
          }
        });
      '';
    })
  ];
}
