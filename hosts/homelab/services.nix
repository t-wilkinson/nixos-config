# hosts/homelab/services.nix
{
  config,
  pkgs,
  unstable,
  lib,
  ...
}:
let
  tunnelId = "c74475c0-1f73-4fae-8bf2-a03f7c8fb6c5"; # .cfargotunnel.com - CNAME cloudflared tunnel
  homelab = config.homelab;
  services = config.homelab.services;
  # exposedServices = lib.filterAttrs (n: v: v.expose) services;
  # publicServices = lib.filterAttrs (n: v: v.isPublic) exposedServices;
  net = config.homelab.network;

  mkCaddyProxy = name: service: {
    name = service.domain;
    value = {
      extraConfig = ''
        reverse_proxy ${service.localEndpoint} {
          header_up X-Real-IP {http.request.remote.host}
          header_up X-Forwarded-Port {http.request.port}
        }
        tls internal
      '';
    };
  };

  mkHomepageEntry = name: service: {
    ${name} = {
      description = service.description;
      href = "https://${service.domain}";
    };
  };

  mkIngressTunnel = name: service: {
    name = service.publicDomain;
    value = {
      service =
        if service.reverseProxy != null then
          "http://${service.reverseProxy}:${toString service.port}"
        else
          "http://${service.localEndpoint}";
      originRequest = {
        httpHostHeader = service.domain;
      };
    };
  };
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
          "home.lab" = homelab.nodes.pi.ipv4;
          "*.home.lab" = homelab.nodes.pi.ipv4;
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
    useRoutingFeatures = "server";
    extraSetFlags = [ "--advertise-routes=${net.cidr}" ];
  };

  # CLOUDFLARE TUNNEL
  services.cloudflared = {
    enable = true;
    tunnels = {
      "${tunnelId}" = {
        # creds generated with 'cloudflared tunnel create'
        credentialsFile = config.sops.secrets."cloudflared_creds".path;
        default = "http_status:404"; # Default Rule: Hide everything else!
        ingress =
          # Public tunnels that do not proxy to another server
          (lib.mapAttrs' mkIngressTunnel (lib.filterAttrs (n: v: v.expose && v.isPublic) services)) // {
            # "${services.mc-server.publicDomain}" = {
            #   service = "tcp://127.0.0.1:${toString services.mc-server.port}";
            #   originRequest = {
            #     httpHostHeader = services.mc-server.domain;
            #   };
            # };
          };

      };
    };
  };

  # CADDY Reverse Proxy (HTTPS / Dashboard)
  services.caddy = {
    enable = true;
    virtualHosts =
      (lib.mapAttrs' mkCaddyProxy (lib.filterAttrs (n: v: v.expose && (v.reverseProxy == null)) services))
      // {
        "${net.domain}".extraConfig = "redir https://${services.dashboard.domain}\ntls internal";
        "${services.dashboard.domain}".extraConfig = ''
          @tailscaleNetwork {
            path /hooks/*
            remote_ip 100.64.0.0/10 fd7a:115c:a1e0::/48 ${net.cidr} 127.0.0.1 ::1
          }

          @forbiddenNetwork {
            path /hooks/*
            not remote_ip 100.64.0.0/10 fd7a:115c:a1e0::/48 ${net.cidr} 127.0.0.1 ::1
          }
          respond @forbiddenNetwork "Access Denied: VPN connection required" 403

          ${
            let
              wolEnabled = (lib.attrByPath [ "wakeonlan" "enable" ] false services);
            in
            lib.optionalString wolEnabled ''
              handle @tailscaleNetwork {
                reverse_proxy 127.0.0.1:${toString services.wakeonlan.port}
              }
            ''
          }

          # Serve the Root CRT at /root.crt
          handle /root.crt {
            root * /var/lib/caddy/.local/share/caddy/pki/authorities/local
            file_server {
              hide root.key
            }
          }

          # Proxy everything else to Homepage
          handle {
            reverse_proxy localhost:${toString services.dashboard.port}
          }

          tls internal
        '';
        "${services.vault.domain}".extraConfig = ''
          @forbiddenAdmin {
            path /admin*
            not remote_ip ${homelab.nodes.pc.cidr} 127.0.0.1
          }
          respond @forbiddenAdmin "Access Denied" 403

          reverse_proxy ${services.vault.localEndpoint} {
            header_up X-Real-IP {http.request.remote.host}
            header_up X-Forwarded-Port {http.request.port}
          }
          tls internal
        '';
        # "${services.immich.domain}".extraConfig = ''
        #   reverse_proxy 10.1.0.1:2283
        #   tls internal
        # '';
        # "${services.nextcloud.domain}".extraConfig = ''
        #   reverse_proxy 10.1.0.1:8081
        #   tls internal
        # '';
      };
  };

  # HOMEPAGE DASHBOARD
  services.homepage-dashboard = {
    enable = true;
    listenPort = services.dashboard.port;
    allowedHosts = "${services.dashboard.domain},${net.domain},localhost,127.0.0.1";
    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
        };
      }
    ];
    services = [
      {
        # "Compute Node" = [
        # ];

        "My Services" = [
          # {
          #   "My Gaming PC" = {
          #     icon = "mdi-desktop-tower";
          #     # Ping the PC to see if it's online
          #     ping = homelab.nodes.pc.ipv4;
          #     network = {
          #       mac = homelab.nodes.pc.mac;
          #     };
          #     widget = {
          #       type = "glances";
          #       url = "http://${homelab.nodes.pc.ipv4}:61208"; # Glances on PC
          #     };
          #     # wakeonlan -i 10.1.0.1 04:7c:16:e6:d1:10
          #     # The Magic Button
          #     siteMonitor = "http://${homelab.nodes.pc.ipv4}:61208";
          #   };
          # }

          {
            "Root Certificate" = {
              icon = "mdi-file-certificate";
              href = "https://${services.dashboard.domain}/root.crt";
              description = "Download to trust HTTPS";
            };

          }
          {
            "Zortex service" = {
              icon = "mdi-bell-ring";
              href = "https://${services.zortex.domain}";
              description = "Notification Hub";
              widget = {
                type = "customapi";
                url = "https://${services.zortex.domain}/api/summary";
                refresh = 60000; # Refresh every minute
                mappings = [
                  {
                    field = "pending_count";
                    label = "Pending";
                    format = "number";
                  }
                  {
                    field = "next_event";
                    label = "Next";
                  }
                ];
              };
            };
          }
          {
            "Jupyter Lab" = {
              icon = "mdi-notebook-outline";
              href = "https://jupyter.${net.publicDomain}";
              description = "Remote Data Science Environment";
            };
          }
        ]
        ++ (lib.optional (lib.attrByPath [ "wakeonlan" "enable" ] false services) {
          "Wake PC" = {
            icon = "mdi-power";
            # href = "https://${services.dashboard.domain}/hooks/wake-pc";
            href = "#wake-pc";
            description = "Send magic packet";
            ping = homelab.nodes.pc.ipv4;
          };
        })
        ++ (lib.mapAttrsToList mkHomepageEntry (
          lib.filterAttrs (n: v: n != "dashboard" && v.expose) services
        ));
      }
    ];
    customJS = ''
      document.addEventListener('click', async (e) => {
        const link = e.target.closest('a[href="#wake-pc"]');
        if (!link) return;

        e.preventDefault();
        e.stopPropagation();

        link.style.opacity = '0.5';

        try {
          const res = await fetch('/hooks/wake-pc');
          const responseText = await res.text();

          if (res.ok) {
            alert(`Success (''${res.status}):\n''${responseText.trim()}`);
          } else {
            alert(`Failed (''${res.status}):\n''${responseText.trim()}`);
          }
        } catch (err) {
          alert(`Error triggering WOL:\n''${err.message}`);
        } finally {
          link.style.opacity = '1';
        }
      });
    '';

  };

  # NFS
  services.nfs.server = {
    enable = true;
    # Fixed ports for firewall stability
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;

    # /srv/pubdrive 10.1.0.1(rw,sync,no_subtree_check,no_root_squash)
    # /srv/misc 10.1.0.1(rw,sync,no_subtree_check,no_root_squash)
    exports = ''
      /srv/sync/personal 10.1.0.1(rw,sync,no_subtree_check,no_root_squash)
      /var/lib/minecraft 10.1.0.1(rw,sync,no_subtree_check,no_root_squash)
    '';
  };
  networking.firewall.allowedTCPPorts = [
    111
    2049
    4000
    4001
    4002
  ];
  networking.firewall.allowedUDPPorts = [
    111
    2049
    4000
    4001
    4002
  ];

  # OPENSSH
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  sops.templates."vaultwarden-env".content = ''
    ADMIN_TOKEN=${config.sops.placeholder.vaultwarden_admin_hash}
    SMTP_PASSWORD=${config.sops.placeholder.google_app_password}
  '';

  # PASSWORD MANAGER
  services.vaultwarden = {
    enable = true;
    package = unstable.vaultwarden;
    environmentFile = config.sops.templates."vaultwarden-env".path;
    config = {
      ROCKET_PORT = services.vault.port;
      SIGNUPS_ALLOWED = false;
      INVITATIONS_ALLOWED = false;
      SHOW_PASSWORD_HINT = false;
      WEBSOCKET_ENABLED = true;
      DOMAIN = "https://${services.vault.publicDomain}";

      SMTP_HOST = "smtp.gmail.com";
      SMTP_FROM = "winston.trey.wilkinson@gmail.com";
      SMTP_PORT = 587;
      SMTP_SECURITY = "starttls";
      SMTP_USERNAME = "winston.trey.wilkinson@gmail.com";
    };
  };

  # NTFY
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://${services.ntfy.domain}";
      listen-http = ":${toString services.ntfy.port}";
      # auth-default-access = "deny-all";
    };
  };

  # ZORTEX: notes, calendar, etc.
  services.zortex = {
    enable = true;
    port = services.zortex.port;
    timezone = "America/New_York";
    ntfy.url = "https://${services.ntfy.domain}";
    ntfy.topic = "zortex-notify";
    # dataDir = "/var/lib/zortex";
  };

  # FAIL2BAN
  environment.etc = {
    # Nextcloud
    "fail2ban/filter.d/nextcloud.conf".text = pkgs.lib.mkDefault (
      pkgs.lib.mkAfter ''
        [Definition]
        _groupsre = (?:(?:,?\s*"\w+":(?:"[^"]+"|\w+))*)
        failregex = ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Login failed:
                    ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Trusted domain error.
        datepattern = ,?\s*"time"\s*:\s*"%%Y-%%m-%%d[T ]%%H:%%M:%%S(%%z)?"
      ''
    );

    # Vaultwarden Filter
    "fail2ban/filter.d/vaultwarden.conf".text = ''
      [Definition]
      # Matches: [INFO] (login_attempt) Failed login attempt. IP: 192.168.1.50
      failregex = .*Failed login attempt. IP: <HOST>.*
                  .*Invalid admin token. IP: <HOST>.*
    '';
  };

  services.fail2ban = {
    enable = true;
    bantime = "24h";

    ignoreIP = [
      homelab.nodes.pc.ipv4
    ];

    jails = {
      # Already enabled for SSHD
      # sshd = ''
      #   enabled = true;
      #   maxretry = 3;
      # '';

      #     # Nextcloud
      #     # Converted to string to avoid "backend option does not exist" error
      #     nextcloud = ''
      #       enabled = true
      #       backend = auto
      #       port = 80,443
      #       protocol = tcp
      #       filter = nextcloud
      #       maxretry = 3
      #       bantime = 86400
      #       findtime = 43200
      #     '';
      #     # logpath = /var/lib/nextcloud/data/nextcloud.log

      vaultwarden = ''
        enabled = true
        filter = vaultwarden
        maxretry = 3
        bantime = 86400
        findtime = 14400
        backend = systemd
        journalmatch = _SYSTEMD_UNIT=vaultwarden.service
      '';
    };
  };
}
