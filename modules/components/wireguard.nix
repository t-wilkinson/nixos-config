{
  pkgs,
  homedir,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];
  networking.wg-quick = {
    interfaces = {
      # wg0 = {
      #   address = [
      #     "10.0.0.2/24"
      #     # "fdc9:281f:04d7:9ee9::2/64"
      #   ];
      #   dns = [
      #     "10.0.0.1"
      #     # "fdc9:281f:04d7:9ee9::1"
      #   ];
      #   privateKeyFile = "${homedir}/.keys/wg-dietpi";

      #   peers = [
      #     {
      #       publicKey = "nbjRfemHGmJ1xzFPRJ2TATg9cBinwsIYquo4IJX6mWU=";
      #       # presharedKeyFile = "/root/wireguard-keys/preshared_from_peer0_key";
      #       allowedIPs = [
      #         "10.0.0.0/24"
      #         # "::/0"
      #       ];
      #       endpoint = "lab.treywilkinson.com:51820";
      #       persistentKeepalive = 25;
      #     }
      #   ];
      # };
    };
  };
}
