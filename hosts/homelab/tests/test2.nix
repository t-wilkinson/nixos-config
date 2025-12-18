{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  networking = {
    hostName = "rpi-homelab";
    useDHCP = false;

    interfaces.wlan0.ipv4.addresses = [
      {
        address = "192.168.1.180";
        prefixLength = 24;
      }
    ];
    defaultGateway = "192.168.1.1";
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];

    wireless = {
      enable = true;
      interfaces = [ "wlan0" ];
      networks."home-wifi-ssid".pskFile = config.age.secrets.wifi.path;
    };
  };

  # SSH: only key-based login
  services.openssh = {
    enable = true;
    permitRootLogin = "no";
    passwordAuthentication = false;
    extraConfig = ''
      PubkeyAuthentication yes
    '';
  };

  users.users."pi" = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIYourPublicKeyHere"
    ];
  };

  # Docker
  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = true;

  # WireGuard
  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "10.0.0.2/24" ];
      listenPort = 51820;
      privateKeyFile = config.age.secrets.wgPrivate.path;
      peers = [
        {
          publicKey = "PeerPubKeyHere";
          allowedIPs = [ "0.0.0.0/0" ];
          endpoint = "your-vpn-server:51820";
          persistentKeepalive = 25;
        }
      ];
    };
  };

  # dnsmasq (lightweight DNS/DHCP)
  services.dnsmasq = {
    enable = true;
    settings = {
      interface = "wlan0";
      domain-needed = true;
      bogus-priv = true;
      # dhcp-range = "192.168.1.50,192.168.1.150,12h";
    };
  };

  # Secrets via agenix
  # age.secrets = {
  #   wifi.file = ./secrets/wifi.age;
  #   wgPrivate.file = ./secrets/wgPrivate.age;
  # };

  system.stateVersion = "24.05";
}
