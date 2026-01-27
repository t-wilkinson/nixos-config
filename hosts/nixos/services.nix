{ ... }:
{
  services.syncthing = {
    enable = true;
    user = "trey";
    dataDir = "/home/trey/.local/state/syncthing"; # Default folder for new synced directories
    configDir = "/home/trey/.config/syncthing";

    openDefaultPorts = true; # 22000/tcp transfer, 21027/udp discovery

    settings = {
      devices = {
        "homelab" = {
          id = "HIAD4WE-UUAOBRY-KXKOWTA-P5HAXBL-FH3NQKF-BZLSGSO-YKNVFFI-4VUZQQE";
          # addresses = [ "tcp://10.1.0.2:22000" ];
        };
      };

      folders = {
        "personal" = {
          id = "personal"; # remove this line?
          path = "/home/trey/dev/t-wilkinson/personal";
          devices = [ "homelab" ];
        };
      };
    };
  };
}
