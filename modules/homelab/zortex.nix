# modules/homelab/zortex.nix
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  homelab = config.homelab;
  services = homelab.services;
  cfg = services.zortex;
in
{
  # Imported unconditionally so services.zortex exists on every node (it is off unless runsHere)
  imports = [ inputs.zortex.nixosModules.default ];

  config = lib.mkMerge [
    {
      # Dashboard tile widget (the tile itself comes from the inventory)
      homelab.services.zortex.dashboard.extra.widget = {
        type = "customapi";
        url = "https://${cfg.domain}/api/summary";
        refresh = 10000; # Every 10 seconds
        mappings = [
          {
            field = "pending_count";
            label = "Pending";
            format = "number";
          }
          {
            field = "next_event";
            label = "Next Event";
          }
        ];
      };
    }

    (lib.mkIf cfg.runsHere {
      # Go 1.26 (nixpkgs 26.05) answers "/raw/../x" with a 307 redirect to the cleaned path
      # where Go <= 1.25 sent 301; zortex's TestFiles only accepts 301/404, so the package
      # failed its checks. The redirect is harmless (the cleaned path is outside /raw and the
      # test still asserts no file content leaks). Patch only while the old assertion is there;
      # fix it upstream in zortex.nvim (app/web/web_test.go) and this does nothing.
      services.zortex.package = (pkgs.callPackage "${inputs.zortex}/nix/zortex.nix" { }).overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          if grep -q 'code != 404 && code != 301 ||' app/web/web_test.go 2>/dev/null; then
            substituteInPlace app/web/web_test.go \
              --replace-fail 'code != 404 && code != 301 ||' 'code != 404 && code != 301 && code != 307 ||'
          fi
        '';
      });

      # ZORTEX: notes, calendar, etc.
      services.zortex = {
        enable = true;
        web.port = services.zortex.port;
        web.writable = true;
        web.htmlScripts = true;
        timezone = "America/New_York";
        ntfy.url = "https://${services.ntfy.domain}";
        ntfy.topic = "zortex-notify";
        ntfy.authTokenFile = config.sops.secrets.ntfy_auth.path;
        notesDir = "/srv/sync/personal/notes";
        notesGroup = toString homelab.groups.zortexdata; # "zortexdata"; # lib.toString homelab.groups.personaldata;
        # dataDir = "/var/lib/zortex";
      };
    })
  ];
}
