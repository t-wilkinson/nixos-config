# hosts/homelab/networking.nix
{ config, hostname, ... }:
let
  pi = config.homelab.nodes.pi; # address on the direct ethernet link to the PC (inventory.nix)
  wifiSsid = "KOI_POND_5G"; # the network name isn't secret; the password is (sops: wifi_psk)
in
{
  sops.templates."nm-wifi-env" = {
    # single quotes: systemd reads the value literally (no $ or \ handling); the password
    # itself must not contain a single quote
    content = "WIFI_PSK='${config.sops.placeholder.wifi_psk}'";
    restartUnits = [ "NetworkManager-ensure-profiles.service" ];
  };

  networking = {
    hostName = hostname;
    # 26.05: NetworkManager drives wpa_supplicant through networking.wireless itself,
    # so forcing it off now conflicts.
    # wireless.enable = false;

    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ]; # for containers
      externalInterface = pi.wanInterface; # the USB Wi-Fi dongle (inventory.nix)
    };

    nameservers = [
      "127.0.0.1"
      "1.1.1.1"
    ];

    networkmanager = {
      # wifi.powersave / scanRandMacAddress: ./wifi.nix
      enable = true;
      dns = "none";

      # Declaratively configure connections so they persist on reboot/rebuild
      ensureProfiles.environmentFiles = [ config.sops.templates."nm-wifi-env".path ];
      ensureProfiles.profiles = {
        # 1. WI-FI PROFILE (Internet Access)
        # "wifi-connection" = {
        #   connection = {
        #     id = "KOI_POND_5G";
        #     type = "wifi";
        #     interface-name = "wlan0";
        #     autoconnect = "true";
        #   };
        #   wifi = {
        #     ssid = "KOI_POND_5G";
        #     mode = "infrastructure";
        #   };
        #   wifi-security = {
        #     key-mgmt = "wpa-psk";
        #     # psk-file = config.sops.secrets.wifi_psk.path;
        #     psk = "password"; # Note: This exposes the password in the Nix store
        #   };
        #   ipv4 = {
        #     method = "auto";
        #   };
        # };

        # Wi-Fi uplink. The password comes from sops (wifi_psk) through the environment file
        # below: NetworkManager-ensure-profiles substitutes $WIFI_PSK when it writes the profile
        # to /run/NetworkManager/system-connections (root-only), so it never enters the Nix store.
        "wifi-uplink" = {
          connection = {
            id = "wifi-uplink";
            type = "wifi";
            interface-name = pi.wanInterface; # the USB dongle (inventory.nix)
            autoconnect = "true";
          };
          wifi = {
            ssid = wifiSsid;
            mode = "infrastructure";
          };
          wifi-security = {
            key-mgmt = "wpa-psk";
            psk = "$WIFI_PSK";
            pmf = 1;
          };
          ipv4.method = "auto";
          ipv6.method = "auto";
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
            address1 = pi.cidr;
            never-default = "true";
          };
        };
      };
    };

    # Firewall rules
    firewall = {
      enable = true;
      allowedTCPPorts = [
        53
        80
        443
        22
        # 51820 # WireGuard (no longer used)
        25565
      ];
      allowedUDPPorts = [
        # 51820 # WireGuard (no longer used)
        9 # WoL
        53 # dns
      ];
      trustedInterfaces = [
        "tailscale0"
        "end0"
        # "wg0"
      ];
    };
  };

  # Enable IP forwarding for WireGuard
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # # WireGuard
  # networking.wireguard.interfaces = {
  #   wg0 = {
  #     ips = [ "${config.homelab.vpnIP}/24" ];
  #     listenPort = 51820;
  #     privateKeyFile = config.sops.secrets.wg_homelab_private_key.path;
  #     peers = [
  #       # Main PC
  #       {
  #         publicKey = "DZqoE/m67JIvOtZR0Q06iV1HvMDpVZskUPj6QxL6chY=";
  #         allowedIPs = [ "${config.homelab.vpnNetwork}.2/32" ];
  #       }
  #       # MacBook
  #       {
  #         publicKey = "Jid4uv1OrkFs6CutQw/A0APB0NQ9RAO1LnzmuzeDgmc=";
  #         allowedIPs = [ "${config.homelab.vpnNetwork}.3/32" ];
  #       }
  #       # Phone
  #       {
  #         publicKey = "WGSdzK7EBpPNIYS9CV8j4CdYC82ciPzcnhN6GVz6AEQ=";
  #         allowedIPs = [ "${config.homelab.vpnNetwork}.4/32" ];
  #       }
  #     ];
  #   };
  # };
}
