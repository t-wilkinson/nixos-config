# modules/homelab/zortex.nix
{
  config,
  lib,
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
