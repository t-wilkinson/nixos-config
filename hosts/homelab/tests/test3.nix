## Run this on your development machine (not the Pi)
#agenix -e -i ~/.ssh/id_ed25519 -r <YOUR_HOST_SSH_PUBLIC_KEY> -o wifi_password.age
#    This command will open your text editor. Paste your WiFi password into the file, save, and close it. `agenix` will encrypt it to `wifi_password.age`.
#
## Generate a private key
#wg genkey | tee privatekey.txt
## Encrypt it with agenix
#agenix -e -i ~/.ssh/id_ed25519 -r <YOUR_HOST_SSH_PUBLIC_KEY> -o wireguard_private_key.age < privatekey.txt
## Clean up the plaintext key
#rm privatekey.txt
#
# nix build .#nixosConfigurations.pi-homelab.config.system.build.sdImage
# Decompress the image: `zstd -d result/sd-image/*.zst`
# sudo dd if=result/sd-image/*.img of=/dev/sdX bs=4M status=progress conv=fsync

{ config, pkgs, ... }:
let
  system = "aarch64-linux";
  user = "nixos"; # The default user
in
{
  # -- Filesystem & Image Configuration --
  # This configures the SD card/SSD image with the specified partitions.
  sdImage = {
    enable = true;
    imageName = "nixos-rpi4-homelab.img";
    compressImage = true;

    # Partition layout
    layout = {
      # 500MB boot partition
      boot = {
        size = "500M";
        fsType = "vfat";
        label = "boot";
        mountPoint = "/boot";
      };
      # 50GB root partition. Adjust size as needed.
      root = {
        size = "50G";
        fsType = "ext4";
        label = "rootfs";
        mountPoint = "/";
      };
      # The rest of the disk for data
      data = {
        size = "100%"; # Use remaining space
        fsType = "ext4";
        label = "data";
        mountPoint = "/data";
      };
    };
  };

  # Mount the filesystems by their labels
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };
    "/" = {
      device = "/dev/disk/by-label/rootfs";
      fsType = "ext4";
    };
    "/data" = {
      device = "/dev/disk/by-label/data";
      fsType = "ext4";
      # Ensures /data is mounted before services that need it start
      neededForBoot = true;
    };
  };

  # -- Bootloader --
  boot.loader.generic-extlinux-compatible.enable = true;

  # -- Networking --
  networking.hostName = "pi-homelab";

  # Wi-Fi configuration
  networking.wireless = {
    enable = true;
    interfaces = [ "wlan0" ];
    networks."<YOUR_WIFI_SSID>" = {
      # The password will be read securely from the agenix-managed file
      pskFile = config.age.secrets.wifi_password.path;
    };
  };

  # Static IP configuration
  networking.interfaces.wlan0 = {
    useDHCP = false;
    ipv4.addresses = [
      {
        address = "192.168.1.180";
        prefixLength = 24;
      }
    ];
  };
  networking.defaultGateway = "192.168.1.1"; # IMPORTANT: Change to your router's IP
  networking.nameservers = [
    "1.1.1.1"
    "8.8.8.8"
  ]; # Cloudflare & Google DNS

  # -- Secrets Management (agenix) --
  age.secrets = {
    wifi_password = {
      file = ./wifi_password.age;
      owner = "root";
      group = "systemd-network";
      mode = "0440";
    };
    wireguard_private_key = {
      file = ./wireguard_private_key.age;
      owner = "root";
      group = "systemd-network";
      mode = "0640";
    };
  };
  # The system needs the host's SSH key to decrypt secrets during the build
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # -- SSH Access --
  services.openssh = {
    enable = true;
    settings = {
      # Disallow password-based logins for security
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Configure the user and add your SSH public key
  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
    ]; # Add user to docker group
    openssh.authorizedKeys.keys = [
      # Replace with your public SSH key
      "<YOUR_SSH_PUBLIC_KEY>"
    ];
  };

  # -- Services --

  # Docker
  virtualisation.docker.enable = true;

  # WireGuard
  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.100.0.1/24" ]; # VPN IP for the Pi
    listenPort = 51820;
    privateKeyFile = config.age.secrets.wireguard_private_key.path;

    # Example peer configuration
    peers = [
      {
        # Public key of your client (e.g., laptop or phone)
        publicKey = "<YOUR_CLIENT_WIREGUARD_PUBLIC_KEY>";
        allowedIPs = [ "10.100.0.2/32" ];
      }
    ];
  };

  # Dnsmasq for DNS on the WireGuard interface
  services.dnsmasq = {
    enable = true;
    extraConfig = ''
      # Only listen on the WireGuard interface
      interface=wg0
      # Example DNS entry
      address=/my-service.local/10.100.0.1
    '';
  };

  # -- System Packages --
  environment.systemPackages = with pkgs; [
    vim
    git
    docker-compose # Add docker-compose
  ];

  # -- System Settings --
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  # system.stateVersion = "25.05"; # Set to your current NixOS version
}
