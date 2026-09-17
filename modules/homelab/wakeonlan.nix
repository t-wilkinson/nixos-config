{
  lib,
  config,
  pkgs,
  ...
}:
let
  homelab = config.homelab;
  enabled = lib.attrByPath [ "homelab" "services" "wakeonlan" "enable" ] false config;
in
{
  config = lib.mkIf enabled (
    let
      cfg = config.homelab.services.wakeonlan;
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
      services.webhook = {
        enable = true;
        port = cfg.port;
        hooks = {
          wake-pc = {
            execute-command = "${pkgs.wakeonlan}/bin/wakeonlan";
            command-working-directory = "/tmp";
            pass-arguments-to-command = [
              {
                source = "string";
                name = "-i";
              }
              {
                source = "string";
                name = homelab.nodes.pc.ipv4;
              }
              {
                source = "string";
                name = homelab.nodes.pc.mac;
              }
            ];
            include-command-output-in-response = true;
          };
        };
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
    }
  );
}
