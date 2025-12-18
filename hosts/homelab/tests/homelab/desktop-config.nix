# ============================================================================
# desktop-config.nix - Configuration snippet for desktop NixOS
# ============================================================================
{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Point-to-point ethernet to Pi
  networking.interfaces.eth0 = {
    useDHCP = false;
    ipv4.addresses = [
      {
        address = "10.0.0.2";
        prefixLength = 30;
      }
    ];
  };

  # Static route for VPN subnet through Pi
  networking.interfaces.eth0.ipv4.routes = [
    {
      address = "10.0.1.0";
      prefixLength = 24;
      via = "10.0.0.1";
    }
  ];

  # Split tunnel routing - send 10.0.0.0/16 through eth0
  networking.localCommands = ''
    ${pkgs.iproute2}/bin/ip route add 10.0.0.0/16 via 10.0.0.1 dev eth0
  '';

  # NFS server for backups
  services.nfs.server = {
    enable = true;
    exports = ''
      /nfs/homelab-backup 10.0.0.1(rw,sync,no_subtree_check,no_root_squash)
    '';
  };

  # Create NFS directory
  systemd.tmpfiles.rules = [
    "d /nfs/homelab-backup 0755 root root -"
  ];

  # Open NFS ports for Pi only
  networking.firewall = {
    interfaces.eth0 = {
      allowedTCPPorts = [
        2049
        111
        20048
      ];
      allowedUDPPorts = [
        2049
        111
        20048
      ];
    };
  };

  # Enable Wake-on-LAN
  networking.interfaces.eth0.wakeOnLan.enable = true;

  # Remote builder configuration - allow Pi to use desktop
  nix = {
    settings = {
      trusted-users = [
        "admin"
        "builder"
      ];
    };

    # Expose builder to Pi
    sshServe = {
      enable = true;
      keys = [
        "ssh-ed25519 AAAAC3Nza... pi-public-key-here"
      ];
    };
  };

  users.users.builder = {
    isSystemUser = true;
    group = "builder";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3Nza... pi-public-key-here"
    ];
  };

  users.groups.builder = { };

  # WireGuard client configuration
  networking.wg-quick.interfaces.wg0 = {
    address = [ "10.0.1.2/24" ];
    privateKeyFile = "/etc/wireguard/private.key";

    peers = [
      {
        publicKey = "PI_PUBLIC_KEY_HERE";
        endpoint = "YOUR_HOME_IP:51820";
        allowedIPs = [ "10.0.1.0/24" ];
        persistentKeepalive = 25;
      }
    ];

    # Split tunnel - only route 10.0.0.0/16 through VPN
    postUp = ''
      ${pkgs.iproute2}/bin/ip route add 10.0.1.0/24 dev wg0
    '';
  };

  # Install Caddy CA certificate
  security.pki.certificates = [
    # Download from http://10.0.0.1:8888/root.crt after first boot
    # Or fetch automatically:
    (builtins.readFile (
      pkgs.fetchurl {
        url = "http://10.0.0.1:8888/root.crt";
        sha256 = "0000000000000000000000000000000000000000000000000000"; # Update after first fetch
      }
    ))
  ];
}
