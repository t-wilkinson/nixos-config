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
      wg0 = {
        address = [
          "10.0.0.2/24"
          # "fdc9:281f:04d7:9ee9::2/64"
        ];
        dns = [
          "8.8.8.8"
          # "fdc9:281f:04d7:9ee9::1"
        ];
        privateKeyFile = "${homedir}/.keys/wg-dietpi";

        peers = [
          {
            publicKey = "2ookyV13cWI5EHrk63QI07OLd5Kw0A9NmQIf52XFzCE=";
            # presharedKeyFile = "/root/wireguard-keys/preshared_from_peer0_key";
            allowedIPs = [
              "10.0.0.0/24"
              # "::/0"
            ];
            endpoint = "pi.treywilkinson.com:51096";
            persistentKeepalive = 25;
          }
        ];
      };
    };
  };
}
