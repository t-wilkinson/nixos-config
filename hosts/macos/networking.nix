{ pkgs, config, ... }:
{
  services.tailscale.enable = true;
  # Verify with: scutil --dns
  environment.etc."resolver/home.lab".text = ''
    nameserver 10.100.0.1
    search home.lab
    timeout 2
  '';

  environment.systemPackages = with pkgs; [
    dnsmasq
  ];
  # services.dnsmasq = {
  #   enable = true;
  #   addresses = {
  #     "home.lab" = "10.100.0.1";
  #     # "pi.vpn" = "10.0.0.1";
  #     # "t.j" = "127.0.0.1";
  #     # "api.t.j" = "127.0.0.1";
  #   };
  # };

  networking.wg-quick.interfaces.wg0 = {
    address = [ "10.100.0.3/32" ];
    privateKeyFile = config.sops.secrets.wg_macos_private_key.path;

    peers = [
      {
        publicKey = "cvzk8zCBE7o/xkeoyCloC53N116VLBubKQYdAAdYsSo=";
        # TODO: use tailscale ip
        endpoint = "100.112.52.7:51820";
        persistentKeepalive = 25;

        allowedIPs = [
          "10.100.0.0/24"
        ];
      }
    ];
  };
}
