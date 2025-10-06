# ============================================================================
# networking.nix - Network configuration
# ============================================================================
{
  config,
  lib,
  pkgs,
  ...
}:

{
  networking = {
    # Enable NetworkManager for WiFi
    networkmanager.enable = true;

    # Firewall configuration
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH
        80 # HTTP (Caddy)
        443 # HTTPS (Caddy)
        51820 # WireGuard
      ];
      allowedUDPPorts = [
        51820 # WireGuard
      ];
      # Trust local interfaces
      trustedInterfaces = [
        "wg0"
        "eth-direct"
      ];
    };

    # Static interface for direct ethernet to desktop
    interfaces.eth0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "10.0.0.1";
          prefixLength = 30; # Point-to-point /30 subnet
        }
      ];
    };

    # Rename eth0 for clarity (optional but nice)
    localCommands = ''
      ${pkgs.iproute2}/bin/ip link set eth0 name eth-direct 2>/dev/null || true
    '';
  };

  # WireGuard VPN server
  networking.wg-quick.interfaces.wg0 = {
    address = [ "10.0.1.1/24" ];
    listenPort = 51820;
    privateKeyFile = config.age.secrets.wireguard-private-key.path;

    # Enable IP forwarding
    postUp = ''
      ${pkgs.iptables}/bin/iptables -A FORWARD -i wg0 -j ACCEPT
      ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.0.1.0/24 -o wlan0 -j MASQUERADE
    '';

    postDown = ''
      ${pkgs.iptables}/bin/iptables -D FORWARD -i wg0 -j ACCEPT
      ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.0.1.0/24 -o wlan0 -j MASQUERADE
    '';

    peers = [
      # Desktop peer
      {
        publicKey = "DESKTOP_PUBLIC_KEY_HERE"; # Replace with actual key
        allowedIPs = [ "10.0.1.2/32" ];
      }
      # Laptop peer
      {
        publicKey = "LAPTOP_PUBLIC_KEY_HERE"; # Replace with actual key
        allowedIPs = [ "10.0.1.3/32" ];
      }
    ];
  };

  # Enable IP forwarding for WireGuard
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # WiFi configuration (will use secret)
  networking.wireless = {
    enable = false; # Using NetworkManager instead
  };
}
