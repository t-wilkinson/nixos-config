{
  config,
  lib,
  pkgs,
  ...
}:
let
  enableNtfy = true;
in
{
  services = {
    hardware.openrgb.enable = true;
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
        PasswordAuthentication = false;
        AllowUsers = null;
        PermitRootLogin = "no";
        KbdInteractiveAuthentication = false;
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
          id = config.homelab.nodes.pi.syncthingId;
          # addresses = [ "tcp://10.1.0.2:22000" ];
        };
      };

      folders = {
        "personal" = {
          id = "personal"; # remove this line?
          path = "/home/trey/dev/t-wilkinson/personal";
          devices = [ "homelab" ];
          fsWatcherEnabled = true;
          fsWatcherDelayS = 1;
        };
      };
    };
  };

  systemd.user.services.ntfy-client = lib.mkIf enableNtfy {
    description = "Ntfy Client Subscription Service";
    wantedBy = [ "default.target" ];
    after = [
      "network-online.target"
      "pipewire.service"
    ];
    wants = [ "pipewire.service" ];

    # Injects these packages into the service's $PATH
    path = with pkgs; [
      ntfy-sh
      libnotify
      bash
      # pulseaudio # paplay
      pipewire # pw-play
      sound-theme-freedesktop
    ];

    environment = {
      ZORTEX_SOUND_DEFAULT = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/message.oga";
    };

    # Using 'script' executes via bash, preserving standard shell quoting and variables.
    # ntfy denies anonymous access; the token goes in via NTFY_TOKEN (not argv, so not in `ps`).
    script = ''
      NTFY_TOKEN="$(cat ${config.sops.secrets.ntfy_auth.path})"
      export NTFY_TOKEN
      exec ntfy subscribe https://${config.homelab.services.ntfy.domain}/zortex-notify "$HOME/.config/ntfy/notify.sh"
    '';

    serviceConfig = {
      Restart = "always";
      RestartSec = "10s";
    };
  };

  environment.systemPackages =
    with pkgs;
    lib.optionals enableNtfy [
      ntfy-sh # systemctl --user enable --now ntfy-client
      libnotify
      pulseaudio
    ];
}
