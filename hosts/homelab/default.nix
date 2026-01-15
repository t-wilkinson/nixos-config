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
in
{
  imports = [
    # Standard hardware config is handled by nixos-hardware module in flake.nix
    ./services.nix
    ./wireguard.nix
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
  users.users.${username} = {
    isNormalUser = true;
    shell = pkgs.fish;
    # hashedPassword = "$6$s0hOYqgJDqS8QCfJ$mv6k9qMFLah6uwV35wmSnH8ADB1i8vtaCe4II0bdjv8iB2IZiYTlI3K6IxMfYw0GqD8fdmyOBC9XxACJOzbGI0";
    # initialHashedPassword = "$6$s0hOYqgJDqS8QCfJ$mv6k9qMFLah6uwV35wmSnH8ADB1i8vtaCe4II0bdjv8iB2IZiYTlI3K6IxMfYw0GqD8fdmyOBC9XxACJOzbGI0";
    initialPassword = "password";
    extraGroups = [
      "wheel"
      "video"
      "docker"
      "input"
      "uinput"
      "libvirtd"
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
            psk = "November13th"; # Note: This exposes the password in the Nix store
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
            address1 = "${directIp}/30";
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
      ];
      allowedUDPPorts = [
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

  # ==========================================
  # 3. SECRETS (SOPS)
  # ==========================================
  sops = {
    defaultSopsFile = ./secrets.yaml;
    # We bake the key into the image so it can decrypt on first boot
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets = {
      wifi_psk = {
        owner = "root";
      };
      nextcloud_admin_pass = {
        owner = "nextcloud";
        group = "nextcloud";
      };
    };
  };

  # Provision the SSH key generated in Phase 1
  environment.etc."ssh/ssh_host_ed25519_key" = {
    source = ./ssh_host_ed25519_key;
    mode = "0600";
  };

  # ==========================================
  # 4. MISC
  # ==========================================
  # Wake on LAN util for turning on the PC
  environment.systemPackages = [ pkgs.wol ];

  system.stateVersion = "24.11";
}
