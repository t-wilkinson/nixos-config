{ pkgs, ... }:
{
  services = {
    # blueman.enable = true;
    # printing.enable = true;
    envfs.enable = true;
    gvfs.enable = true;
    openssh = {
      enable = true;
      ports = [
        22
        6229
      ];
      settings = {
        PasswordAuthentication = true;
        AllowUsers = null;
        PermitRootLogin = "no";
      };
    };
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
          user = "greeter";
        };
      };
    };

    # wayvnc = {
    #   enable = true;
    #   listen = "0.0.0.0";
    #   # passwordFile = "/etc/wayvnc.pass"; create this manually
    # };
    # spice-vdagentd.enable = true;
    xserver = {
      enable = true;
      videoDrivers = [ "modesetting" ];
      displayManager.startx.enable = true;
      desktopManager.gnome = {
        enable = true;
        extraGSettingsOverridePackages = [ pkgs.nautilus-open-any-terminal ];
      };
      # xkb.layout = "us";
      # xkb.options = "eurosign:e,caps:escape";
    };

    keyd = {
      enable = true;
      keyboards = {
        default = {
          ids = [ "*" ];
          settings = {
            main = {
              # control = "oneshot(control)";
              capslock = "overload(control, esc)";
              # esc = "`";
            };
            # Make esc work on my small 60% fn keyboard
            # "esc:S" = {
            #   esc = "~";
            # };
            # fn = {
            #   esc = "esc";
            # };
          };
        };
      };
    };
  };

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
