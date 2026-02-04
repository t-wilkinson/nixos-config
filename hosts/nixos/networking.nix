# hosts/nixos/networking.nix
{
  pkgs,
  config,
  lib,
  username,
  ...
}:
let
  homelab = config.homelab;
  mcServerPort = 25565;
  rconPort = 25575;
  homelabDirectGateway = "10.1.0.2";
in
{
  services.resolved = {
    enable = true;
    fallbackDns = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };

  networking = {
    hostName = "nixos";
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
    };

    # Add route to get to homelab IP through direct ethernet connection
    # interfaces.enp3s0.ipv4.routes = [
    #   {
    #     address = config.homelab.homelabIP;
    #     prefixLength = 32;
    #     via = homelabDirectGateway;
    #   }

    #   {
    #     address = "${config.homelab.containerNetwork}.0";
    #     prefixLength = 24;
    #     via = homelabDirectGateway;
    #   }
    # ];

    interfaces.enp3s0.wakeOnLan.enable = true;
    firewall =
      let
        kdePortRanges = {
          from = 1714;
          to = 1764;
        };
      in
      {
        allowedTCPPortRanges = [ kdePortRanges ];
        allowedUDPPortRanges = [ kdePortRanges ];
        allowedUDPPorts = [
          9 # wol
        ];
        allowedTCPPorts = [
          mcServerPort
          rconPort
          22
          # 6229 # ssh
          # 5900 # vnc
        ];
      };
  };

  # Use pi DNS for everything
  networking.networkmanager.ensureProfiles.profiles = {
    "wired-homelab" = {
      connection.type = "ethernet";
      connection.id = "wired-homelab";
      connection.interface-name = "enp3s0";
      connection.autoconnect = true;
      "802-3-ethernet".wake-on-lan = "magic"; # sudo ethtool -s enp3s0 wol gp (magic physical)

      ipv4.method = "manual";
      ipv4.addresses = "10.1.0.1/30";
      # ipv4.gateway = "10.1.0.2";
      ipv4.dns = "10.1.0.2";
      # ipv4.dns-search = "~home.lab,home.lab";
      ipv4.dns-search = "~home.lab";
      ipv4.never-default = "true";
      # ipv4.routes = "${homelab.homelabIP}/32 next-hop=${homelabDirectGateway}, ${homelab.containerNetwork}.0/24 ${homelabDirectGateway}";
    };
  };

  networking.networkmanager.dispatcherScripts = [
    {
      source = pkgs.writeText "homelab-routes" ''
        case "$2" in
          up)
            ${pkgs.iproute2}/bin/ip route replace ${homelab.homelabIP}/32 via ${homelabDirectGateway} dev enp3s0
            ${pkgs.iproute2}/bin/ip route replace ${homelab.containerNetwork}.0/24 via ${homelabDirectGateway} dev enp3s0
            ;;
        esac
      '';
      type = "basic";
    }
  ];

  # systemd.services.add-custom-routes = {
  #   description = "Add custom routes for homelab direct connection";
  #   wantedBy = [ "multi-user.target" ];
  #   # Ensure it runs after the network is actually up
  #   after = [
  #     "network-online.target"
  #     "NetworkManager.service"
  #   ];
  #   wants = [ "network-online.target" ];

  #   serviceConfig = {
  #     Type = "oneshot";
  #     # RemainAfterExit is key: it tells systemd the service is "active"
  #     # even after ExecStart finishes, allowing ExecStop to run later.
  #     RemainAfterExit = true;

  #     ExecStart = ''
  #       ${pkgs.iproute2}/bin/ip route replace ${homelab.homelabIP}/32 via ${homelabDirectGateway} dev enp3s0
  #       ${pkgs.iproute2}/bin/ip route replace ${homelab.containerNetwork}.0/24 via ${homelabDirectGateway} dev enp3s0
  #     '';
  #     # ExecStop = ''
  #     #   -${pkgs.iproute2}/bin/ip route del ${homelab.homelabIP}/32 via ${homelabDirectGateway} dev enp3s0
  #     #   -${pkgs.iproute2}/bin/ip route del ${homelab.containerNetwork}.0/24 via ${homelabDirectGateway} dev enp3s0
  #     # '';
  #   };
  # };

  # Split tunnel VPN with homelab
  # networking.wg-quick.interfaces = {
  #   wg0 = {
  #     address = [ "10.100.0.2/32" ];
  #     privateKeyFile = config.sops.secrets.wg_nixos_private_key.path;

  #     # Split tunnel:
  #     # Only route traffic for the VPN subnet (10.100.0.x)
  #     # AND the Homelab subnet (10.1.0.x) through the tunnel.
  #     peers = [
  #       {
  #         publicKey = "cvzk8zCBE7o/xkeoyCloC53N116VLBubKQYdAAdYsSo=";
  #         endpoint = "10.1.0.2:51820"; # wg server endpoint
  #         persistentKeepalive = 25;

  #         allowedIPs = [
  #           "10.100.0.0/24"
  #         ];
  #       }
  #     ];
  #   };
  # };

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
