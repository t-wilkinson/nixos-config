{ pkgs, hostname, username, config, ... }: 

{
  # nix
  documentation.nixos.enable = false; # .desktop
  nixpkgs.config.allowUnfree = true;
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

  services = {
    # spice-vdagentd.enable = true;
    # printing.enable = true;
    # openssh.enable = true;
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
              control = "oneshot(control)";
              capslock = "overload(control, esc)";
              esc = "`";
            };
            # Make esc work on small fn keyboard, modularize this
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

  security = {
    rtkit.enable = true;
    polkit.enable = true;
    pam.services.swaylock = { };
    # pam.services.swaylock-effects = {};
  };

  # dconf
  programs = {
    # zsh.enable = true;
    fish.enable = true;
    dconf.enable = true;
    # steam = {
    #   enable = true;
    #   remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    #   dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    # };
    firefox = {
      enable = true;
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
    # gnupg.agent = {
    #   enable = true;
    #   enableSSHSupport = true;
    # };
  };

  # Packages
  # $ nix search <package>
  environment = {
    localBinInPath = true;
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
      # nodePackages_latest.neovim
    ];
  };

  # ZRAM
  zramSwap.enable = false;
  zramSwap.memoryPercent = 100;

  # logind
  services.logind.extraConfig = ''
    HandlePowerKey=ignore
    HandleLidSwitch=suspend
    HandleLidSwitchExternalPower=ignore
  '';

  # user
  users = {
    defaultUserShell = pkgs.fish;
    users.${username} = {
      isNormalUser = true;
      shell = pkgs.fish;
      extraGroups = [ "networkmanager" "wheel" "video" "input" "uinput" "libvirtd" "lxd" ];
    };
  };

  # network
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
  };
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
  # networking.interfaces.wlan0.ipv4.addresses = [ {
  #   address = "192.168.0.100";
  #   prefixLength = 24;
  # } ];
  # networking.defaultGateway = "192.168.0.1";
  # networking.nameservers = [ "8.8.8.8" ];
  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  # systemd.network.links."10-wan" = {
  #   matchConfig.PermanentMACAddress = "";
  #   linkConfig.Name = "wan";
  # };

  # bluetooth
  # hardware.bluetooth = {
  #   enable = true;
  #   powerOnBoot = false;
  # };

  # Boot
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
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

  # Virtualisation
  virtualisation = {
    lxd.enable = false;
    libvirtd = {
      enable = false;
      qemu = {
        swtpm.enable = false;
        ovmf.enable = false;
        ovmf.packages = [ pkgs.OVMFFull.fd ];
      };
    };
    spiceUSBRedirection.enable = true;
  };

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
    # nvidia.modesetting.enable = true;
  };

  environment.sessionVariables = {
    # WLR_NO_HARDWARE_CURSORS = "1"; # if your cursor becomes invisible
    NIXOS_OZONE_WL = "1"; # hint to electron apps to use wayland
    NIXPKGS_ALLOW_UNFREE = "1";
    NIXPKGS_ALLOW_INSECURE = "1";
  };

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

  system.stateVersion = "23.11"; # If you touch this, Covid 2.0 will be released
}
