{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    dnsmasq
  ];
  services.dnsmasq = {
    enable = true;
    addresses = {
      "pi.vpn" = "10.0.0.1";
      "dev" = "127.0.0.1";
      "api.dev" = "127.0.0.1";
    };
  };
}
