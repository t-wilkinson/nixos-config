# hosts/homelab/default.nix
{
  config,
  pkgs,
  lib,
  username,
  ...
}:
let
  directIp = "10.1.0.2"; # The static IP for the direct Ethernet link to your PC
  gatewayIp = "10.0.0.1"; # Replace with your actual home Router IP
  vpnIP = "10.100.0.1";
in
{
  imports = [
    # Standard hardware config is handled by nixos-hardware module in flake.nix
    ./services.nix
  ];

  nix.settings = {
    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  documentation.man.generateCaches = false; # Fish enables this by default but it takes a lot of time.
  security.sudo.wheelNeedsPassword = false; # So remote building doesn't keep asking for passwords

  # ==========================================
  # 1. BOOT & HARDWARE
  # ==========================================
  # Use generic extlinux compatible bootloader (standard for Pi images)
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # Enable binfmt emulation so you can build this locally on x86
  nixpkgs.hostPlatform = "aarch64-linux";

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  programs.fish.enable = true;
  users.mutableUsers = false;
  users.groups.personaldata = { }; # for exposing to synced directory to nextcloud
  users.users.${username} = {
    isNormalUser = true;
    shell = pkgs.fish;
    hashedPasswordFile = config.sops.secrets.homelab_password_hash.path;
    extraGroups = [
      "personaldata"
      "wheel"
      "video"
      "docker"
      "input"
      "uinput"
      "libvirtd"
      "syncthing"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIID64Ajd0fkDjs12IacKz28QzlyedzzaAL8V6YmjTPd/ winston.trey.wilkinson@gmail.com"
    ];
  };

  hardware.enableRedistributableFirmware = true;
  hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];

  # ==========================================
  # 2. NETWORKING
  # ==========================================
  networking = {
    hostName = "homelab";
    nameservers = [
      "127.0.0.1"
      "1.1.1.1"
    ];
    networkmanager = {
      enable = true;
      dns = "none";

      # Declaratively configure connections so they persist on reboot/rebuild
      ensureProfiles.profiles = {
        # 1. WI-FI PROFILE (Internet Access)
        "wifi-connection" = {
          connection = {
            id = "KOI_POND_5G";
            type = "wifi";
            interface-name = "wlan0";
            autoconnect = "true";
          };
          wifi = {
            ssid = "KOI_POND_5G";
            mode = "infrastructure";
          };
          wifi-security = {
            key-mgmt = "wpa-psk";
            psk-file = config.sops.secrets.wifi_psk.path;
            # psk = ""; # Note: This exposes the password in the Nix store
          };
          ipv4 = {
            method = "auto";
          };
        };

        # 2. ETHERNET PROFILE (Direct Link to PC)
        "direct-ethernet" = {
          connection = {
            id = "direct-ethernet";
            type = "ethernet";
            interface-name = "end0";
          };
          ipv4 = {
            method = "manual";
            address1 = "10.1.0.2/30";
            never-default = "true";
          };
        };
      };
    };

    # Disable wpa_supplicant to avoid conflicts with NetworkManager
    wireless.enable = false;

    # Firewall rules
    firewall = {
      enable = true;
      allowedTCPPorts = [
        53
        80
        443
        22
        51820 # WireGuard
      ];
      allowedUDPPorts = [
        51820 # WireGuard
        9 # WoL
        53 # dns
      ];
      trustedInterfaces = [
        "end0"
        "wg0"
      ];
    };
  };

  # Enable IP forwarding for WireGuard
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # WireGuard
  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "${vpnIP}/24" ];
      listenPort = 51820;
      privateKeyFile = config.sops.secrets.wg_homelab_private_key.path;
      peers = [
        # Main PC
        {
          publicKey = "DZqoE/m67JIvOtZR0Q06iV1HvMDpVZskUPj6QxL6chY=";
          allowedIPs = [ "10.100.0.2/32" ];
        }
        # MacBook
        {
          publicKey = "Jid4uv1OrkFs6CutQw/A0APB0NQ9RAO1LnzmuzeDgmc=";
          allowedIPs = [ "10.100.0.3/32" ];
        }
        # Phone
        {
          publicKey = "WGSdzK7EBpPNIYS9CV8j4CdYC82ciPzcnhN6GVz6AEQ=";
          allowedIPs = [ "10.100.0.4/32" ];
        }
      ];
    };
  };

  # ==========================================
  # 3. SECRETS (SOPS)
  # ==========================================
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ ];
    gnupg.sshKeyPaths = [ ];
    age.keyFile = "/etc/ssh/age.key";

    secrets = {
      wifi_psk = {
        owner = "root";
      };
      homelab_password_hash = {
        owner = "root";
      };
      wg_homelab_private_key = {
        owner = "root";
      };
      nextcloud_admin_pass = {
        owner = "nextcloud";
        group = "nextcloud";
      };
      cloudflared_creds = {
        owner = "root";
        group = "root";
      };
      google_app_password = {
        owner = "root";
      };
    };
  };

  security.pki.certificateFiles = [
    ./homelab-root.crt
  ];

  # Provision the SSH key generated in Phase 1
  # environment.etc."ssh/ssh_host_ed25519_key" = {
  #   source = ./ssh_host_ed25519_key;
  #   mode = "0600";
  # };

  # ==========================================
  # 4. MISC
  # ==========================================
  environment.systemPackages = with pkgs; [
    wol # Wake on LAN util for turning on the PC
    wireguard-tools
    syncthing
    tree
    ripgrep
    fd
  ];

  system.stateVersion = "24.11";

  fileSystems."/mnt/backup" = {
    device = "/dev/disk/by-uuid/D404BD3804BD1E84";
    fsType = "ntfs";
    options = [
      "nofail"
      "x-systemd.automount"
    ];
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
