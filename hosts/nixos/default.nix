# hosts/nixos/default.nix
{
  pkgs,
  lib,
  username,
  config,
  ...
}:
{
  imports = [
    ./audio.nix
    ./filesystem.nix
    ./gnome.nix
    ./hardware.nix
    ./home-manager
    ./homelab.nix
    ./locale.nix
    ./networking.nix
    ./services.nix
    ./vmware.nix
    ../../modules/shared.nix
    ../../modules/virtualisation.nix
  ];

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # NIX
  documentation.nixos.enable = false;
  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
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
    variables = {
      QT_QPA_PLATFORM = "wayland";
    };
    sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
      #   # WLR_NO_HARDWARE_CURSORS = "1"; # if your cursor becomes invisible
      #   NIXOS_OZONE_WL = "1"; # hint to electron apps to use wayland
      #   # NIXPKGS_ALLOW_UNFREE = "1";
      #   # NIXPKGS_ALLOW_INSECURE = "1";
      #   # LIBVA_DRIVER_NAME = "iHD";
    };
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
        "dialout"
        (lib.mkIf config.virtualisation.docker.enable "docker")
        (lib.mkIf config.networking.networkmanager.enable "networkmanager")
      ];
      openssh.authorizedKeys.keyFiles = [
        "/home/${username}/.ssh/authorized_keys"
        # (lib.mkIf (keys ? ${config.networking.hostName}) keys.${config.networking.hostName})
      ];
    };
  };

  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita";
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk # Common fallback for file pickers/dialogs
    ];
    config.common.default = "*"; # Ensures portals are used correctly
  };

  environment.systemPackages = with pkgs; [
    droidcam

    adwaita-qt
    qt6.qtwayland
    qt5.qtwayland
    kdePackages.kdeconnect-kde
    libsForQt5.qtstyleplugin-kvantum # The engine
    kdePackages.qtstyleplugin-kvantum # For Qt6 apps
    xdragon # for lf

    # inputs.agenix.packages."${config.system}".default
    # inputs.agenix.packages."x86_64-linux".default
    nix-ld
    gtk3
    efibootmgr
    iproute2
    psmisc # tools that use /proc
    usbutils
    stdenv.cc.cc.lib

    # need the following for file uploads to work
    dbus
    nss
    gnutls
    libglvnd
  ];

  programs = {
    ssh.startAgent = true;
    kdeconnect = {
      enable = true;
      package = pkgs.gnomeExtensions.gsconnect;
    };
    # Run dynamically linked stuff
    firefox = {
      enable = true;
      nativeMessagingHosts.packages = [
        pkgs.libsForQt5.plasma-browser-integration
        pkgs.gnomeExtensions.gsconnect
      ];
    };
    fish.enable = true;
    zsh.enable = true;
    dconf.enable = true;
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
      enableSSHSupport = false;
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

  # Suspend on power button press
  services.logind.extraConfig = ''
    HandlePowerKey=suspend
    HandleLidSwitch=suspend
    HandleLidSwitchExternalPower=ignore
  '';

  # Prevent the computer from waking up from super sensitive mouse
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", DRIVER=="xhci_hcd", ATTR{power/wakeup}="disabled"
  '';

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      wg_nixos_private_key = {
        owner = "root";
      };
    };
  };

  # DROIDCAM
  # # boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelModules = [
  #   "v4l2loopback"
  #   "snd-aloop"
  # ];
  # boot.extraModulePackages = [
  #   config.boot.kernelPackages.v4l2loopback
  # ];
  # boot.extraModprobeConfig = ''
  #   options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
  # '';

  system.stateVersion = "24.05"; # If you touch this, Covid 2.0 will be released
}
