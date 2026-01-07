{ pkgs, ... }:
{
  # Use pi DNS for everything
  # networking.networkmanager.insertNameservers = [ "10.1.0.2" ];

  networking.networkmanager.ensureProfiles.profiles = {
    "Wired Homelab" = {
      connection.type = "ethernet";
      connection.id = "Wired Homelab";
      connection.interface-name = "enp3s0";
      connection.autoconnect = true;

      ipv4.method = "manual";
      ipv4.addresses = "10.1.0.1/30";
      # ipv4.gateway = "10.0.0.1";
      ipv4.dns = "10.1.0.2";
      ipv4.dns-search = "~homelab.lan";
      ipv4.never-default = "true";
    };
  };

  # networkmanager.connectionConfig."static-wifi" = {
  #   type = "wifi";
  #   interfaceName = "wlo1";
  #   ipv4 = {
  #     method = "manual";
  #     addresses = [
  #       {
  #         address = "192.168.1.181";
  #         prefix = 24;
  #       }
  #     ];
  #     gateway = "192.168.1.1";
  #     dns = [
  #       "1.1.1.1"
  #       "8.8.8.8"
  #     ];
  #   };
  # };

  # networking.wireguard.enable = true;
  # networking.wireguard.interfaces = {
  #   # "wg0" is the network interface name. You can name the interface arbitrarily.
  #   wg0 = {
  #     # Determines the IP address and subnet of the client's end of the tunnel interface.
  #     ips = [ "10.100.0.2/24" ];
  #     listenPort = 51820; # to match firewall allowedUDPPorts (without this wg uses random port numbers)

  #     # Path to the private key file.
  #     #
  #     # Note: The private key can also be included inline via the privateKey option,
  #     # but this makes the private key world-readable; thus, using privateKeyFile is
  #     # recommended.
  #     privateKeyFile = "path to private key file";

  #     peers = [
  #       # For a client configuration, one peer entry for the server will suffice.

  #       {
  #         # Public key of the server (not a file path).
  #         publicKey = "{server public key}";

  #         # Forward all the traffic via VPN.
  #         allowedIPs = [ "0.0.0.0/0" ];
  #         # Or forward only particular subnets
  #         #allowedIPs = [ "10.100.0.1" "91.108.12.0/22" ];

  #         # Set this to the server IP and port.
  #         endpoint = "{server ip}:51820"; # ToDo: route to endpoint not automatically configured https://wiki.archlinux.org/index.php/WireGuard#Loop_routing https://discourse.nixos.org/t/solved-minimal-firewall-setup-for-wireguard-client/7577

  #         # Send keepalives every 25 seconds. Important to keep NAT tables alive.
  #         persistentKeepalive = 25;
  #       }
  #     ];
  #   };
  # };
}
