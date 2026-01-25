# ============================================================================
# configuration.nix - Main system configuration for Raspberry Pi 4
# ============================================================================
{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./services.nix
    ./networking.nix
    ./secrets.nix
  ];

  # Boot configuration
  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    kernelParams = [
      "console=ttyAMA0,115200"
      "console=tty1"
    ];
    # Optimize for low power
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
    };
  };

  # Hostname
  networking.hostName = "homelab-pi";

  # Timezone
  time.timeZone = "America/New_York";

  # Minimal system - no GUI, no docs
  documentation.enable = false;
  documentation.nixos.enable = false;

  # Users
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "podman"
    ];
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
      "ssh-ed25519 AAAAC3Nza... your-key-here"
    ];
  };

  # Enable SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Podman setup with docker-compose compatibility
  virtualisation.podman = {
    enable = true;
    dockerCompat = true; # Creates docker alias
    dockerSocket.enable = true;
    defaultNetwork.settings.dns_enabled = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # Enable container networking
  networking.firewall.trustedInterfaces = [ "podman+" ];

  # Required packages
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    tmux
    podman-compose
    wireguard-tools
    ethtool
    wakeonlan
    curl
    rsync
  ];

  # agenix
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # Remote building configuration
  nix = {
    settings = {
      trusted-users = [
        "admin"
        "@wheel"
      ];
      builders-use-substitutes = true;
    };

    # Use desktop as remote builder
    buildMachines = [
      {
        hostName = "10.0.0.2";
        system = "aarch64-linux";
        maxJobs = 8;
        speedFactor = 4;
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
        mandatoryFeatures = [ ];
      }
    ];

    distributedBuilds = true;

    # Fallback to local builds if remote fails
    extraOptions = ''
      builders-use-substitutes = true
      fallback = true
    '';

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Enable flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Auto-upgrade
  system.autoUpgrade = {
    enable = true;
    flake = "/etc/nixos#homelab-pi";
    dates = "weekly";
    allowReboot = false;
  };

  # Power optimization
  powerManagement.cpuFreqGovernor = "ondemand";

  system.stateVersion = "25.05";
}
