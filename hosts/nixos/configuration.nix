{ config, pkgs, inputs, outputs, ... }: 

let
  inherit (outputs) hostname username system;
in
{
  # nix
  documentation.nixos.enable = false; # .desktop
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
      allowBroken = true;
      packageOverrides = pkgs: {
        intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
      };
    };
  };
  nix.settings = {
    experimental-features = "nix-command flakes";
    auto-optimise-store = true;
    substituters = [
      "https://hyprland.cachix.org"
      "https://nix-gaming.cachix.org"
      # Nixpkgs-Wayland
      "https://cache.nixos.org"
      "https://nixpkgs-wayland.cachix.org"
      "https://nix-community.cachix.org"
      # Nix-community
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      # Nixpkgs-Wayland
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      # Nix-community
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
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

  security = {
    rtkit.enable = true;
    polkit.enable = true;
    pam.services.swaylock = { };
    # pam.services.swaylock-effects = {};
  };

  services = {
    spice-vdagentd.enable = true;
    # printing.enable = true;
    openssh = {
      # enable = true;
      # hostKeys = [
      #   { path = "/etc/ssh/ssh_host_rsa_key"; bits = 4096; type = "rsa"; }
      # ];
    };
    envfs.enable = true;
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
          user = "greeter";
        };
      };
    };
    gvfs.enable = true;
    xserver = {
      enable = true;
      # videoDrivers = ["nvidia"];
      # xkb.layout = "us";
      # xkb.options = "eurosign:e,caps:escape";
      displayManager.startx.enable = true;
      desktopManager.gnome = {
        enable = true;
        extraGSettingsOverridePackages = [
          pkgs.nautilus-open-any-terminal
        ];
      };
    };
    keyd = {
      enable = true;
      keyboards = {
        default = {
          ids = ["*"];
          settings = {
            main = {
              # control = "oneshot(control)";
              capslock = "overload(control, esc)";
              esc = "`";
            };
            # Ctrl + [ = esc; adds lag to 'esc' though
            # "[:C" = {
            #   "[" = "esc";
            # };
            # Make esc work on small fn keyboard. modularize this?
            "esc:S" = {
              esc = "~";
            };
          };
        };
      };
    };
  };

  swapDevices = [ {
    device = "/var/lib/swapfile";
    size = 16*1024;
  } ];

  # ZRAM
  zramSwap = {
    enable = true;
    # memoryPercent = 50;
    # priority = 5;
  };

  programs = {
    fish.enable = true;
    zsh.enable = true;
    dconf.enable = true;
    # gamemode.enable = true;
    firefox = {
      enable = true;
      preferences = {
        "widget.use-xdg-desktop-portal.file-picker" = 1;
      };
      nativeMessagingHosts.packages = [ pkgs.plasma5Packages.plasma-browser-integration ];
    };
    # Run dynamically linked stuff
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        # Add any missing dynamic libraries for unpackaged programs
        # here, NOT in environment.systemPackages
      ];
    };
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      # enableExtraSocket = true;
      # extraConfig = ''
      #   # enable-ssh-support
      #   allow-preset-passphrase;
      # '';
      # pinentryPackage = pkgs.pinentry-gnome3;
      # defaultCacheTtl = 34560000;
      # defaultCacheTtlSsh = 34560000;
      # maxCacheTtl = 34560000;
      # maxCacheTtlSsh = 34560000;
    };
    steam = {
      enable = true;
      # gamescopeSession.enable = true;
      # remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      # dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    };
  };

  # Packages
  # $ nix search <package>
  environment = {
    localBinInPath = true;
    sessionVariables = {
      # WLR_NO_HARDWARE_CURSORS = "1"; # if your cursor becomes invisible
      NIXOS_OZONE_WL = "1"; # hint to electron apps to use wayland
      NIXPKGS_ALLOW_UNFREE = "1";
      NIXPKGS_ALLOW_INSECURE = "1";
      LIBVA_DRIVER_NAME = "iHD";
    };
    systemPackages = with pkgs; [
      curl
      zsh
      fish
      git
      gh
      wget
      nixpkgs-fmt
      nixfmt-classic
      vim
      neovim
      gnumake
      gtk3
      efibootmgr
      inputs.agenix.packages."${system}".default

      # need the following for file uploads to work
      dbus 
      nss
      gnutls
      libglvnd
    ];
  };

  # logind
  services.logind.extraConfig = ''
    HandlePowerKey=suspend
    HandleLidSwitch=suspend
    HandleLidSwitchExternalPower=ignore
  '';

  # user
  users = {
    defaultUserShell = pkgs.fish;
    # users.peter = {
    #   isNormalUser = true;
    #   shell = pkgs.zsh;
    #   extraGroups = [ "networkmanager" "wheel" "video" "input" "uinput" ];
    # };
    users.trey = {
      isNormalUser = true;
      shell = pkgs.fish;
      extraGroups = [ "networkmanager" "wheel" "video" "input" "uinput" ];
    };
  };

  # networking.networkmanager.enable = lib.mkForce false;

  # systemd.services."systemd-networkd".environment.SYSTEMD_LOG_LEVEL = "debug";
  # networking = {
  #   hostName = hostname;
  #   # nftables.enable = true;
  #   # networkmanager.enable = false;
  #   firewall.allowedTCPPorts = [ 22 5900 ];
  #   # localCommands =
  #   #   ''
  #   #     ip -6 addr add 2001:610:685:1::1/64 dev eth0
  #   #   '';
  # };

  # hardware.bluetooth = {
  #   enable = true;
  #   powerOnBoot = false;
  # };

  # networking.usePredictableInterfaceNames = true;

  # Boot
  boot = {
    # Use the systemd-boot EFI boot loader.
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    # doesn't work, mac addresses are randomized
    # initrd.services.udev.rules = ''
    #   SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", \
    #   ATTR{address}=="52:54:00:12:01:01", KERNEL=="enp*", NAME="eth0"
    #   SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", \
    #   ATTR{address}=="8e:10:ab:93:d5:31", KERNEL=="enp*", NAME="wlan0"
    # '';
  };

  # boot.loader.grub.device = "/dev/nvme1n1p1";
  # boot = {
  #   tmp.cleanOnBoot = true;
  #   supportedFilesystems = [ "btrfs" "ext4" "fat32" "ntfs" ];
  #   loader = {
  #     grub = {
  #       enable = true;
  #       device = "nodev";
  #       efiSupport = true;
  #       useOSProber = true;
  #     };
  #     efi.canTouchEfiVariables = true;
  #   };
  #   # kernelPackages = pkgs.linuxPackages_xanmod_latest;
  #   # kernelPatches = [{
  #   #   name = "enable RT_FULL";
  #   #   patch = null;
  #   #   # TODO: add realtime patch: PREEMPT_RT y
  #   #   extraConfig = ''
  #   #     PREEMPT y
  #   #     PREEMPT_BUILD y
  #   #     PREEMPT_VOLUNTARY n
  #   #     PREEMPT_COUNT y
  #   #     PREEMPTION y
  #   #   '';
  #   # }];
  #   # extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];
  #   # kernelModules = [ "acpi_call" ];
  #   # make 3.5mm jack work
  #   # extraModprobeConfig = ''
  #   #   options snd_hda_intel model=headset-mode
  #   # '';
  # };

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
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   # useXkbConfig = true; # use xkb.options in tty.
  # };

  # Audio
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # jack.enable = true;
    wireplumber.enable = true;
  };

  # config = mkIf cfg.server.libvert.enable {
  #   # https://technicalsourcery.net/posts/nixos-in-libvirt/
  #   boot.kernelModules = [ "kvm-intel" "kvm-amd" ];
  #
  #   virtualisation.libvirtd.enable = true;
  #   virtualisation.libvirtd.allowedBridges =
  #     [ "${cfg.libvert.bridgeInterface}" ];
  #
  #   networking.interfaces."${cfg.libvert.bridgeInterface}".useDHCP = true;
  #   networking.bridges = {
  #     "${cfg.libvert.bridgeInterface}" = {
  #       interfaces = [ "${cfg.libvert.ethInterface}" ];
  #     };
  #   };
  # };

  # hyprland
  programs.hyprland = {
    enable = true;
    # nvidiaPatches = true;
    xwayland.enable = true; 
  };

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
    ];
  };
  # hardware.nvidia.modesetting.enable = true;

  fonts = {
    packages = with pkgs; [
      fira-code
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      font-awesome
      source-han-sans
      source-han-sans-japanese
      source-han-serif-japanese
    ];
    fontconfig.defaultFonts = {
      serif = [ "Noto Serif" "Source Han Serif" ];
      sansSerif = [ "Noto Sans" "Source Han Sans" ];
    };
  };

  system.stateVersion = "24.05"; # If you touch this, Covid 2.0 will be released
}
