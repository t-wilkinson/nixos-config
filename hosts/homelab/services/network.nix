{ config, ... }:
let
  tunnelId = "c74475c0-1f73-4fae-8bf2-a03f7c8fb6c5"; # cloudflared tunnel
  services = config.my-lab.services;
in
{
  # BLOCY
  services.resolved.enable = false; # Disable systemd-resolved to free port 53 for Blocky
  services.resolved.extraConfig = "DNSStubListener=no";
  services.blocky = {
    enable = true;
    settings = {
      ports.dns = 53;
      # ports.http = 4000;
      upstreams.groups.default = [
        "https://1.1.1.1/dns-query" # Cloudflare
        "https://8.8.8.8/dns-query" # Google
      ];

      # Access your services via these domains
      customDNS = {
        customTTL = "1h";
        mapping = {
          # Map main domain and all subdomains to the Pi's Direct IP
          "home.lab" = config.my-lab.vpnIP;
          "*.home.lab" = config.my-lab.vpnIP;
        };
      };

      # Ad Blocking
      blocking = {
        # enable = true;
        blackLists = {
          ads = [ "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts" ];
        };
        clientGroupsBlock.default = [ "ads" ];
      };
    };
  };

  # TAILSCALE: Mesh network
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  # CLOUDFLARE TUNNEL
  services.cloudflared = {
    enable = true;
    tunnels = {
      "${tunnelId}" = {
        # creds generated with 'cloudflared tunnel create'
        credentialsFile = config.sops.secrets."cloudflared_creds".path;
        default = "http_status:404"; # Default Rule: Hide everything else!
        ingress = {
          "${services.mc-server.publicDomain}" = {
            service = "tcp://127.0.0.1:${toString services.mc-server.port}";
            originRequest = {
              httpHostHeader = services.mc-server.domain;
            };
          };
          "${services.immich.publicDomain}" = {
            service = "http://localhost:${toString services.immich.port}";
            originRequest = {
              httpHostHeader = services.immich.domain;
            };
          };
          "${services.nextcloud.publicDomain}" = {
            service = "http://${services.nextcloud.containerIP}:${toString services.nextcloud.port}";
            originRequest = {
              httpHostHeader = services.nextcloud.domain;
            };
          };
        };
      };
    };
  };
}
