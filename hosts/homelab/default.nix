{
  config,
  pkgs,
  lib,
  ...
}:
let
  # The static IP for the direct Ethernet link to your PC
  directIp = "10.1.0.2";
  gatewayIp = "10.0.0.1"; # Replace with your actual home Router IP
in
{
  imports = [
    # Standard hardware config is handled by nixos-hardware module in flake.nix
  ];

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

  # ==========================================
  # 2. NETWORKING
  # ==========================================
  networking = {
    hostName = "homelab";
    useDHCP = false;

    # WI-FI (Internet Access)
    wireless = {
      enable = true;
      networks."YourSSID" = {
        pskRaw = "ext:wifi_psk"; # Read from sops secret
      };
      # We read the secret into an environment file for wpa_supplicant
      secretsFile = config.sops.secrets.wifi_psk.path;
    };

    # INTERFACES
    interfaces = {
      # Wi-Fi Interface (Gateway to Internet)
      "wlan0" = {
        useDHCP = true;
      };

      # Ethernet (Direct link to PC)
      "end0" = {
        ipv4.addresses = [
          {
            address = directIp;
            prefixLength = 30; # Limits subnet to 2 IPs (10.0.0.1 and .2)
          }
        ];
      };
    };

    # Firewall rules
    firewall = {
      enable = true;
      allowedTCPPorts = [
        80
        443
        22 # SSH
      ];
      allowedUDPPorts = [
        51820 # WireGuard
        9 # WoL
      ];
      trustedInterfaces = [ "end0" ]; # Trust the direct link to PC
    };
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
      wireguard_private_key = {
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
  # 4. SERVICES
  # ==========================================

  # Caddy Reverse Proxy (HTTPS / Dashboard)
  services.caddy = {
    enable = true;
    virtualHosts = {
      # Access via http://homelab.local or http://10.0.0.2
      ":80" = {
        extraConfig = ''
          respond / "Go to /dashboard" 302
        '';
      };
      ":80/dashboard/*" = {
        extraConfig = "reverse_proxy localhost:8082";
      };
      ":80/vault/*" = {
        extraConfig = "reverse_proxy localhost:8000";
      };
      ":80/ntfy/*" = {
        extraConfig = "reverse_proxy localhost:8080";
      };
    };
  };

  # Homepage Dashboard
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    services = [
      {
        "My Services" = [
          {
            "Vaultwarden" = {
              href = "/vault/";
              description = "Password Manager";
            };
          }
          {
            "Nextcloud" = {
              href = "http://${directIp}:8081"; # Nextcloud is complex to proxy on subpath without config
              description = "Files";
            };
          }
        ];
      }
    ];
  };

  # Vaultwarden
  services.vaultwarden = {
    enable = true;
    config = {
      ROCKET_PORT = 8000;
      SIGNUPS_ALLOWED = false;
    };
  };

  # Ntfy
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "http://${directIp}/ntfy";
      listen-http = ":8080";
      auth-default-access = "deny-all";
    };
  };

  # Nextcloud
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud32;
    hostName = "homelab.local";
    config = {
      adminuser = "admin";
      dbtype = "sqlite";
      adminpassFile = config.sops.secrets.nextcloud_admin_pass.path;
    };
    settings.trusted_domains = [
      "localhost"
      directIp
      "homelab.local"
    ];
  };

  # WireGuard
  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "10.100.0.1/24" ];
      listenPort = 51820;
      privateKeyFile = config.sops.secrets.wireguard_private_key.path;
      peers = [
        # Example Peer (Your Phone)
        {
          publicKey = "YOUR_PHONE_PUBLIC_KEY";
          allowedIPs = [ "10.100.0.2/32" ];
        }
      ];
    };
  };

  # Wake on LAN util for turning on the PC
  environment.systemPackages = [ pkgs.wol ];

  system.stateVersion = "24.11";
}
