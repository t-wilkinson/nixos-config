{
  config,
  inputs,
  lib,
  pkgs,
  unstable,
  username,
  ...
}:
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
    auto-optimise-store = true;
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
    # sessionVariables = {
    #   # WLR_NO_HARDWARE_CURSORS = "1"; # if your cursor becomes invisible
    #   NIXOS_OZONE_WL = "1"; # hint to electron apps to use wayland
    #   # NIXPKGS_ALLOW_UNFREE = "1";
    #   # NIXPKGS_ALLOW_INSECURE = "1";
    #   # LIBVA_DRIVER_NAME = "iHD";
    # };
  };

  users = {
    defaultUserShell = pkgs.fish;
    users.${username} = {
      isNormalUser = true;
      shell = pkgs.fish;
      extraGroups = [
        "wheel"
        "video"
        "input"
        "uinput"
        # "render"
        "libvirtd"
        (lib.mkIf config.networking.networkmanager.enable "networkmanager")
      ];
      openssh.authorizedKeys.keyFiles = [
        "/home/${username}/.ssh/authorized_keys"
        # (lib.mkIf (keys ? ${config.networking.hostName}) keys.${config.networking.hostName})
      ];
    };
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    defaultGateway = "192.168.1.1";
    # interfaces.enp3s0 = {
    #   wakeOnLan.enable = true;
    # };
    # interfaces.wlo1 = {
    #   useDHCP = false;
    #   ipv4.addresses = [
    #     {
    #       address = "192.168.1.181";
    #       prefixLength = 24;
    #     }
    #   ];
    # };
    firewall.allowedTCPPorts = [
      22
      6229 # ssh
      5900 # vnc
    ];
    # networkmanager.connectionConfig."static-wifi" = {
    #   type = "wifi";
    #   interfaceName = "wlo1";
    #   ipv4 = {
    #     method = "manual";
    #     addresses = [
    #       {
    #         address = "192.168.1.181";
    #         prefix = 24;
    #       }
    #     ];
    #     gateway = "192.168.1.1";
    #     dns = [
    #       "1.1.1.1"
    #       "8.8.8.8"
    #     ];
    #   };
    # };
  };

  programs = {
    fish.enable = true;
    zsh.enable = true;
    dconf.enable = true;
    # Run dynamically linked stuff
    firefox = {
      enable = true;
      nativeMessagingHosts.packages = [ pkgs.libsForQt5.plasma-browser-integration ];
    };
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        # Add any missing dynamic libraries for unpackaged programs
        # here, NOT in environment.systemPackages
      ];
    };
    steam.enable = true;
    # hyprland = {
    #   enable = true;
    #   withUWSM = true;
    #   xwayland.enable = true;
    #   # nvidiaPatches = true;
    #   package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    #   # make sure to also set the portal package, so that they are in sync
    #   portalPackage =
    #     inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    # };
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      # enableExtraSocket = true;
      pinentryPackage = pkgs.pinentry-gnome3;
      settings = {
        # allow-preset-passphrase = true;
        # enable-ssh-support
        default-cache-ttl = 34560000;
        default-cache-ttl-ssh = 34560000;
        max-cache-ttl = 34560000;
        max-cache-ttl-ssh = 34560000;
      };
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

  systemd = {
    user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };

  services.logind.extraConfig = ''
    HandlePowerKey=suspend
    HandleLidSwitch=suspend
    HandleLidSwitchExternalPower=ignore
  '';

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
  hardware.i2c.enable = true; # for ags ddcutil

  security = {
    rtkit.enable = true;
    polkit.enable = true;
    pam.services.swaylock = { };
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
