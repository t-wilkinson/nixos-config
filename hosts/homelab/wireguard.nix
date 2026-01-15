{ config, ... }:
let
  vpnIP = "10.100.0.1";
in
{
  sops.secrets.wg_homelab_private_key = {
    owner = "root";
  };

  networking.firewall.allowedUDPPorts = [ 51820 ];
  networking.firewall.allowedTCPPorts = [ 51820 ];

  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "${vpnIP}/24" ];
      listenPort = 51820;
      privateKeyFile = config.sops.secrets.wg_homelab_private_key.path;
      peers = [
        # Main PC
        {
          publicKey = "DZqoE/m67JIvOtZR0Q06iV1HvMDpVZskUPj6QxL6chY=";
          allowedIPs = [ "10.100.0.2/32" ];
        }
        # MacBook
        {
          publicKey = "Jid4uv1OrkFs6CutQw/A0APB0NQ9RAO1LnzmuzeDgmc=";
          allowedIPs = [ "10.100.0.3/32" ];
        }
        # Phone
        {
          publicKey = "WGSdzK7EBpPNIYS9CV8j4CdYC82ciPzcnhN6GVz6AEQ=";
          allowedIPs = [ "10.100.0.4/32" ];
        }
      ];
    };
  };

}
