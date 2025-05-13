{
  lib,
  config,
  pkgs,
  unstable,
  inputs,
  ...
}:
let
  user = "trey";
in
{
  # nix
  documentation.nixos.enable = false; # .desktop
  nixpkgs = {
    config = {
      # packageOverrides = pkgs: {
      #   intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
      # };
    };
  };

  nix.settings = {
    substituters = [
      "https://hyprland.cachix.org"
      "https://nix-gaming.cachix.org"
      "https://nixpkgs-wayland.cachix.org"
    ];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
    ];
  };

  environment = {
    localBinInPath = true;
    sessionVariables = {
      # WLR_NO_HARDWARE_CURSORS = "1"; # if your cursor becomes invisible
      NIXOS_OZONE_WL = "1"; # hint to electron apps to use wayland
      # NIXPKGS_ALLOW_UNFREE = "1";
      # NIXPKGS_ALLOW_INSECURE = "1";
      # LIBVA_DRIVER_NAME = "iHD";
    };
  };

  users = {
    defaultUserShell = pkgs.fish;
    users.${user} = {
      isNormalUser = true;
      shell = pkgs.fish;
      extraGroups = [
        "wheel"
        "video"
        "input"
        "render"
        "uinput"
        (lib.mkIf config.networking.networkmanager.enable "networkmanager")
      ];
      openssh.authorizedKeys.keyFiles = [
        "/home/${user}/.ssh/authorized_keys"
        # (lib.mkIf (keys ? ${config.networking.hostName}) keys.${config.networking.hostName})
      ];
    };
  };

  networking = {
    interfaces.enp3s0 = {
      wakeOnLan.enable = true;
    };
    firewall.allowedTCPPorts = [
      6229 # ssh
      5900 # vnc
    ];
  };

  programs = {
    fish.enable = true;
    zsh.enable = true;
    dconf.enable = true;
    # Run dynamically linked stuff
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        # Add any missing dynamic libraries for unpackaged programs
        # here, NOT in environment.systemPackages
      ];
    };
    steam.enable = true;
    hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
      # nvidiaPatches = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      # make sure to also set the portal package, so that they are in sync
      portalPackage =
        inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };
  };

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
        PasswordAuthentication = false;
        AllowUsers = null;
        PermitRootLogin = "no";
      };
    };
    # greetd = {
    #   enable = true;
    #   settings = {
    #     default_session = {
    #       # command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
    #       # user = "greeter";
    #     };
    #   };
    # };

    # wayvnc = {
    #   enable = true;
    #   listen = "0.0.0.0";
    #   # passwordFile = "/etc/wayvnc.pass"; create this manually
    # };
    # spice-vdagentd.enable = true;
    # xserver = {
    #   enable = true;
    #   videoDrivers = [ "modesetting" ];
    #   # xkb.layout = "us";
    #   # xkb.options = "eurosign:e,caps:escape";
    #   # displayManager.startx.enable = true;
    #   # desktopManager.gnome = {
    #   #   enable = true;
    #   #   extraGSettingsOverridePackages = [ pkgs.nautilus-open-any-terminal ];
    #   # };
    # };

    keyd = {
      enable = true;
      keyboards = {
        default = {
          ids = [ "*" ];
          settings = {
            main = {
              # control = "oneshot(control)";
              capslock = "overload(control, esc)";
              esc = "`";
            };
            # Make esc work on my small 60% fn keyboard
            "esc:S" = {
              esc = "~";
            };
          };
        };
      };
    };
  };

  # systemd = {
  #   user.services.polkit-gnome-authentication-agent-1 = {
  #     description = "polkit-gnome-authentication-agent-1";
  #     wantedBy = [ "graphical-session.target" ];
  #     wants = [ "graphical-session.target" ];
  #     after = [ "graphical-session.target" ];
  #     serviceConfig = {
  #       Type = "simple";
  #       ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
  #       Restart = "on-failure";
  #       RestartSec = 1;
  #       TimeoutStopSec = 10;
  #     };
  #   };
  # };

  services.logind.extraConfig = ''
    HandlePowerKey=suspend
    HandleLidSwitch=suspend
    HandleLidSwitchExternalPower=ignore
  '';

  # Locale
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Audio
  # sound.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # jack.enable = true;
    wireplumber.enable = true;
  };
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
      mesa.drivers
      libdrm
    ];
  };
  # hardware.nvidia.modesetting.enable = true;

  security = {
    rtkit.enable = true;
    polkit.enable = true;
    # pam.services.swaylock = { };
    # pam.services.swaylock-effects = {};
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024;
    }
  ];

  zramSwap = {
    enable = true;
    # memoryPercent = 50;
    # priority = 5;
  };

  boot = {
    # Use the systemd-boot EFI boot loader.
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  system.stateVersion = "24.05"; # If you touch this, Covid 2.0 will be released
}
