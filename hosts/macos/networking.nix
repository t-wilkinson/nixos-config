{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    dnsmasq
  ];
  services.dnsmasq = {
    enable = false;
    addresses = {
      # "pi.vpn" = "10.0.0.1";
      # "t.j" = "127.0.0.1";
      # "api.t.j" = "127.0.0.1";
    };
  };
}
