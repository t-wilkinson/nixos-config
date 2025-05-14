{ ... }:
{
  networking.wireguard.enable = true;
  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "10.0.0.2/24" ];
      listenPort = 51820;
      privateKeyFile = "~/.keys/dietpi-private";
      peers = [
        {
          publicKey = "~/.keys/dietpi-server";
          allowedIPs = [ "0.0.0.0/0" ];
          endpoint = "pc.treywilkinson.com:51820";
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
