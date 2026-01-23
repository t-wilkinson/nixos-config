{ config, hostname, ... }:
let
  directIP = "10.1.0.2"; # IP from direct ethernet connection to PC
in
{

  networking = {
    hostName = hostname;
    # Disable wpa_supplicant to avoid conflicts with NetworkManager
    wireless.enable = false;

    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "wlan0";
    };

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
            address1 = "${directIP}/30";
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
        51820 # WireGuard
        25565
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
      ips = [ "${config.my-lab.vpnIP}/24" ];
      listenPort = 51820;
      privateKeyFile = config.sops.secrets.wg_homelab_private_key.path;
      peers = [
        # Main PC
        {
          publicKey = "DZqoE/m67JIvOtZR0Q06iV1HvMDpVZskUPj6QxL6chY=";
          allowedIPs = [ "${config.my-lab.vpnNetwork}.2/32" ];
        }
        # MacBook
        {
          publicKey = "Jid4uv1OrkFs6CutQw/A0APB0NQ9RAO1LnzmuzeDgmc=";
          allowedIPs = [ "${config.my-lab.vpnNetwork}.3/32" ];
        }
        # Phone
        {
          publicKey = "WGSdzK7EBpPNIYS9CV8j4CdYC82ciPzcnhN6GVz6AEQ=";
          allowedIPs = [ "${config.my-lab.vpnNetwork}.4/32" ];
        }
      ];
    };
  };
}
