# hosts/homelab/services.nix
{
  config,
  pkgs,
  lib,
  ...
}:
let
  services = config.homelab.services;

  mkCaddyProxy = name: service: {
    name = service.domain;
    value = {
      extraConfig = ''
        reverse_proxy ${service.endpoint} {
          header_up X-Real-IP {http.request.remote.host}
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
in
{
  # CADDY Reverse Proxy (HTTPS / Dashboard)
  services.caddy = {
    enable = true;
    virtualHosts = (lib.mapAttrs' mkCaddyProxy (lib.filterAttrs (n: v: v.expose) services)) // {
      "${config.homelab.domain}".extraConfig = "redir https://${services.dashboard.domain}\ntls internal";
      "${services.dashboard.domain}".extraConfig = ''
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
    };
  };

  # HOMEPAGE DASHBOARD
  services.homepage-dashboard = {
    enable = true;
    listenPort = services.dashboard.port;
    allowedHosts = "${services.dashboard.domain},${config.homelab.domain},localhost,127.0.0.1";
    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
        };
      }
      # {
      #   # New Widget: Wake PC
      #   search = {
      #     provider = "custom";
      #     url = "http://10.1.0.1:8000"; # Optional: if you run a status agent on PC
      #     target = "_blank";
      #   };
      # }
    ];
    services = [
      {
        # "Compute Node" = [
        #   {
        #     "My Gaming PC" = {
        #       icon = "mdi-desktop-tower";
        #       # Ping the PC to see if it's online
        #       ping = "10.1.0.1";
        #       widget = {
        #         type = "glances";
        #         url = "http://10.1.0.1:61208"; # Glances on PC
        #       };
        #       # The Magic Button
        #       siteMonitor = "http://10.1.0.1:61208";
        #     };
        #   }
        # ];
        "My Services" = [
          {
            "Root Certificate" = {
              icon = "mdi-file-certificate";
              href = "https://${services.dashboard.domain}/root.crt";
              description = "Download to trust HTTPS";
            };
          }
        ]
        ++ (lib.mapAttrsToList mkHomepageEntry (
          lib.filterAttrs (n: v: n != "dashboard" && v.expose) services
        ));
      }
    ];
  };

  # NFS
  services.nfs.server = {
    enable = true;
    # Fixed ports for firewall stability
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
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

  # PASSWORD MANAGER
  services.vaultwarden = {
    enable = true;
    config = {
      ROCKET_PORT = services.vault.port;
      SIGNUPS_ALLOWED = true;
      SHOW_PASSWORD_HINT = false;
      DOMAIN = "https://${services.vault.domain}";
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

  # services.fail2ban = {
  #   enable = true;
  #   bantime = "24h";

  #   ignoreIP = [
  #     "${config.homelab.vpnNetwork}.0/24"
  #     "10.1.0.1"
  #   ];

  #   jails = {
  #     # SSH (Standard jail)
  #     # sshd = ''
  #     #   enabled = true
  #     #   mode = aggressive
  #     # '';

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

  #     # Vaultwarden
  #     vaultwarden = ''
  #       enabled = true
  #       backend = systemd
  #       filter = vaultwarden
  #       maxretry = 3
  #       bantime = 86400
  #       findtime = 14400
  #     '';
  #   };
  # };
}
