# hosts/homelab/services.nix
{
  config,
  pkgs,
  unstable,
  lib,
  ...
}:
let
  tunnelId = net.cloudflareTunnelId;
  homelab = config.homelab;
  services = config.homelab.services;
  net = config.homelab.network;
  nodes = config.homelab.nodes;
  # exposedServices = lib.filterAttrs (n: v: v.expose) services;
  # publicServices = lib.filterAttrs (n: v: v.isPublic) exposedServices;

  # Deployed (anywhere in the homelab) and reachable through Caddy
  exposedServices = lib.filterAttrs (n: v: v.enable && v.expose) services;
  # ...and also reachable from the internet through the tunnel
  publicServices = lib.filterAttrs (n: v: v.isPublic && v.publicDomain != null) exposedServices;
  privateServices = lib.filterAttrs (n: v: !v.isPublic && v.publicDomain != null) exposedServices;

  # LAN/tailnet client ranges. With trusted_proxies below, {client_ip} is the real visitor
  # (Cf-Connecting-Ip) for tunnel traffic, so internet requests never match these.
  privateRanges = lib.concatStringsSep " " (net.privateRanges ++ [ net.cidr ]);

  # One site block per service, answering on both its private and public names:
  #   LAN/tailnet: x.home.lab and x.treywilkinson.com
  #   internet:    x.treywilkinson.com, public services only (the tunnel only routes those)
  mkCaddyProxy =
    name: service:
    let
      domains = [ service.domain ] ++ lib.optional (service.publicDomain != null) service.publicDomain;
      hostnames = lib.concatStringsSep ", " domains;

      proxyTo = endpoint: ''
        reverse_proxy ${endpoint} {
          header_up X-Real-IP {client_ip}
          header_up X-Forwarded-Port {http.request.port}
          ${service.proxyConfig}
        }
      '';

      # Private services: refuse anything that isn't LAN/tailnet (defense in depth; the tunnel
      # doesn't route their names anyway)
      lanOnly = lib.optionalString (!service.isPublic) ''
        @notLan not client_ip ${privateRanges}
        respond @notLan "Not found" 404
      '';
      # Everything below runs inside `route`, i.e. in the order written. (At the top level Caddy
      # sorts `handle` before `respond`, so access checks written as `respond` would never fire.)

      # service.paths = { "/notes" = "127.0.0.1:8090"; }: the prefix is passed on
      pathRoutes = lib.concatStrings (
        lib.mapAttrsToList (path: endpoint: ''
          redir ${path} ${path}/
          handle ${path}/* {
            ${proxyTo endpoint}
          }
        '') (service.paths or { })
      );
    in
    {
      name = hostnames;
      value = {
        extraConfig = ''
          @httpProto {
            header X-Forwarded-Proto http
          }
          redir @httpProto https://{host}{uri} permanent
          route {
            ${lanOnly}
            ${service.extraConfig}
            ${pathRoutes}
            handle {
              ${proxyTo service.localEndpoint}
            }
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
      service = "https://127.0.0.1:443";
      # if service.reverseProxy != null then
      #   "http://${service.reverseProxy}:${toString service.port}"
      # else
      #   "http://${service.localEndpoint}";
      originRequest = {
        # Keep the public Host header so apps build public links; Caddy's site block
        # answers on both names. TLS to Caddy on loopback uses its internal CA.
        # httpHostHeader = service.domain;
        originServerName = service.publicDomain;
        noTLSVerify = true;
      };
    };
  };
in
{
  # BLOCKY
  services.resolved.enable = false; # Disable systemd-resolved to free port 53 for Blocky
  # services.resolved.extraConfig = "DNSStubListener=no"; # removed in 26.05; resolved is off anyway
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
          "${net.domain}" = nodes.pi.ipv4;
          "*.${net.domain}" = nodes.pi.ipv4;
        }
        # Private services also answer on their public name, but only on the LAN/tailnet.
        # Public services keep resolving to Cloudflare (real certificate, e.g. Bitwarden mobile).
        // lib.mapAttrs' (n: v: lib.nameValuePair v.publicDomain nodes.pi.ipv4) privateServices;
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
          # Only enabled public services; everything else falls through to the 404 default
          (lib.mapAttrs' mkIngressTunnel publicServices) // {
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

  # Per-service additions to the generated Caddy site blocks (run inside `route`, in order)
  homelab.services.dashboard.extraConfig = ''
    # Wake-on-LAN hook (the dashboard itself is LAN/tailnet only)
    ${lib.optionalString services.wakeonlan.enable ''
      handle /hooks/* {
        reverse_proxy 127.0.0.1:${toString services.wakeonlan.port}
      }
    ''}

    # Serve the Root CRT at /root.crt
    handle /root.crt {
      root * /var/lib/caddy/.local/share/caddy/pki/authorities/local
      file_server {
        hide root.key
      }
    }
  '';
  # Rewrite Host to 127.0.0.1:8384 so Syncthing's host check passes behind the proxy
  # (replaces gui.insecureSkipHostcheck)
  homelab.services.syncthing.proxyConfig = ''
    header_up Host {upstream_hostport}
  '';
  homelab.services.vault.extraConfig = ''
    # Admin page: LAN/tailnet only. Internet traffic arrives through the tunnel carrying the
    # visitor's real IP ({client_ip} = Cf-Connecting-Ip), so it can't pass this.
    @adminNotLan {
      path /admin*
      not client_ip ${privateRanges}
    }
    respond @adminNotLan "Access Denied" 403
  '';

  # CADDY Reverse Proxy (HTTPS / Dashboard)
  services.caddy = {
    enable = true;
    # cloudflared connects from loopback; trust its Cf-Connecting-Ip header so {client_ip}
    # (and X-Forwarded-For / X-Real-IP sent to apps) is the real visitor, not 127.0.0.1.
    globalConfig = ''
      servers {
        trusted_proxies static 127.0.0.1/32 ::1/128
        client_ip_headers Cf-Connecting-Ip
      }
    '';
    virtualHosts = (lib.mapAttrs' mkCaddyProxy exposedServices) // {
      "${net.domain}".extraConfig = "redir https://${services.dashboard.domain}\ntls internal";
    };
  };

  # HOMEPAGE DASHBOARD
  services.homepage-dashboard = {
    enable = true;
    listenPort = services.dashboard.port;
    allowedHosts = "${services.dashboard.domain},${services.dashboard.publicDomain},${net.domain},localhost,127.0.0.1";
    settings = {
      title = "Wilkinson Homelab";
      favicon = "https://nixos.org/favicon.png";
      theme = "dark";
      color = "slate";
      layout = {
        "Infrastructure" = {
          style = "row";
          columns = 2;
        };
        "Applications" = {
          style = "row";
          columns = 2;
        };
      };
    };

    widgets = [
      {
        glances = {
          # Use internal localhost/container IP to avoid hairpin routing through Caddy
          url = "http://127.0.0.1:${toString services.glances.port}";
          # url = "https://${services.glances.domain}"; # alternatively via your domain
          version = 4; # nixpkgs 24.11 / unstable defaults to Glances v4
          cpu = true;
          mem = true;
          cputemp = true;
          uptime = true;
          disk = [
            "/"
            homelab.drives.pi-pubdrive
          ];
        };
      }
      # {
      #   resources = {
      #     cpu = true;
      #     memory = true;
      #     disk = "/";
      #     cputemp = true;
      #   };
      # }
      {
        search = {
          provider = "duckduckgo";
          target = "_blank";
          showSearch = true;
        };
      }
      {
        datetime = {
          format = {
            timeStyle = "short";
            dateStyle = "full";
          };
        };
      }
    ];

    services = [
      {
        "Applications" = [
          {
            "Zortex Hub" = {
              icon = "mdi-bell-ring";
              href = "https://${services.zortex.domain}";
              description = "Notification & Organization Hub";
              widget = {
                type = "customapi";
                url = "https://${services.zortex.domain}/api/summary";
                refresh = 10000; # Every 10 seconds
                mappings = [
                  {
                    field = "pending_count";
                    label = "Pending";
                    format = "number";
                  }
                  {
                    field = "next_event";
                    label = "Next Event";
                  }
                ];
              };
            };
          }
          {
            "Actual Budget" = {
              icon = "mdi-finance";
              href = "https://${services.actual-budget.domain}";
              description = "Envelope Budgeting";
              ping = "https://${services.actual-budget.domain}";
            };
          }
          {
            "Mealie" = {
              icon = "mdi-silverware-fork-knife";
              href = "https://${services.mealie.domain}";
              description = "Recipe Manager";
              # ping = "https://${services.mealie.domain}";
            };
          }
          {
            "Nextcloud" = {
              icon = "nextcloud";
              href = "https://${services.nextcloud.domain}";
              description = "Files & Sync";
            };
          }
          {
            "Immich" = {
              icon = "immich";
              href = "https://${services.immich.domain}";
              description = "Photos";
            };
          }
          {
            "Pastebin" = {
              icon = "";
              href = "https://${services.pastebin.domain}";
              description = "Pastebin (microbin)";
            };
          }
          {
            "Ntfy" = {
              icon = "";
              href = "https://${services.ntfy.domain}";
              description = "Notifications";
            };
          }
        ];
      }
      {
        "Infrastructure" = [
          {
            "Syncthing" = {
              icon = "syncthing";
              href = "https://${services.syncthing.domain}";
              description = "P2P File Synchronization";
              # ping = services.syncthing.localEndpoint;
            };
          }
          {
            "Vaultwarden" = {
              icon = "vaultwarden";
              href = "https://${services.vault.domain}";
              description = "Password Manager";
              # ping = "https://${services.vault.domain}";
            };
          }
          {
            "Blocky DNS" = {
              icon = "mdi-dns";
              href = "http://${nodes.pi.ipv4}:4000"; # If you enable Blocky's HTTP port
              description = "Ad-blocking & Local DNS";
            };
          }
          {
            "Root Certificate" = {
              icon = "mdi-file-certificate";
              href = "https://${services.dashboard.domain}/root.crt";
              description = "Trust local HTTPS";
            };
          }
        ];
      }
      {
        "Compute Nodes" = [
          {
            "Glances" = {
              icon = "";
              href = "https://${services.glances.domain}";
              description = "Monitoring";
            };
          }
          {
            "Jupyter Lab" = {
              icon = "jupyter";
              href = "https://${services.jupyter.domain}";
              description = "Remote Data Science";
            };
          }
          (lib.mkIf (services.wakeonlan.enable or false) {
            "Gaming PC (WOL)" = {
              icon = "mdi-power";
              href = "#wake-pc";
              description = "Send magic packet";
              # ping = nodes.pc.ipv4;
            };
          })
        ];
      }
    ];

    # services = [
    #   {
    #     "Applications" = [
    #       # {
    #       #   "My Gaming PC" = {
    #       #     icon = "mdi-desktop-tower";
    #       #     # Ping the PC to see if it's online
    #       #     ping = homelab.nodes.pc.ipv4;
    #       #     network = {
    #       #       mac = homelab.nodes.pc.mac;
    #       #     };
    #       #     widget = {
    #       #       type = "glances";
    #       #       url = "http://${homelab.nodes.pc.ipv4}:61208"; # Glances on PC
    #       #     };

    #       {
    #         "Root Certificate" = {
    #           icon = "mdi-file-certificate";
    #           href = "https://${services.dashboard.domain}/root.crt";
    #           description = "Download to trust HTTPS";
    #         };

    #       }
    #       {
    #         "Zortex service" = {
    #           icon = "mdi-bell-ring";
    #           href = "https://${services.zortex.domain}";
    #           description = "Notification Hub";
    #           widget = {
    #             type = "customapi";
    #             url = "https://${services.zortex.domain}/api/summary";
    #             refresh = 60000; # Refresh every minute
    #             mappings = [
    #               {
    #                 field = "pending_count";
    #                 label = "Pending";
    #                 format = "number";
    #               }
    #               {
    #                 field = "next_event";
    #                 label = "Next";
    #               }
    #             ];
    #           };
    #         };
    #       }
    #       {
    #         "Jupyter Lab" = {
    #           icon = "mdi-notebook-outline";
    #           href = "https://jupyter.${net.publicDomain}";
    #           description = "Remote Data Science Environment";
    #         };
    #       }
    #     ]
    #     ++ (lib.optional (lib.attrByPath [ "wakeonlan" "enable" ] false services) {
    #       "Wake PC" = {
    #         icon = "mdi-power";
    #         # href = "https://${services.dashboard.domain}/hooks/wake-pc";
    #         href = "#wake-pc";
    #         description = "Send magic packet";
    #         ping = nodes.pc.ipv4;
    #       };
    #     })
    #     ++ (lib.mapAttrsToList mkHomepageEntry (
    #       lib.filterAttrs (n: v: n != "dashboard" && v.expose) services
    #     ));
    #   }
    # ];

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
      ${homelab.drives.personal} ${nodes.pc.ipv4}(rw,sync,no_subtree_check,no_root_squash)
      ${homelab.drives.minecraft} ${nodes.pc.ipv4}(rw,sync,no_subtree_check,no_root_squash)
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
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
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
  # Private instance: nothing is readable or writable without auth. One provisioned admin user
  # (homelab.username) with one access token, ntfy_auth (tk_ + 29 chars, from `ntfy token generate`).
  # Clients send `Authorization: Bearer <token>`; the web UI/apps log in as <username> with the
  # token as the password.
  services.ntfy-sh = {
    enable = true;
    # Declarative users/tokens (auth-users / auth-tokens) need ntfy >= 2.14; 26.05 ships 2.26.
    # package = unstable.ntfy-sh;
    settings = {
      base-url = "https://${services.ntfy.domain}";
      listen-http = "127.0.0.1:${toString services.ntfy.port}"; # only Caddy and local clients
      behind-proxy = true;
      auth-default-access = "deny-all";
    };
  };

  # NTFY_AUTH_USERS needs a bcrypt hash, which a sops template can't compute, so build the
  # env file at boot. EnvironmentFile is read by systemd as root, so it can stay root-only.
  systemd.services.ntfy-sh-auth = {
    description = "Render ntfy declarative auth from sops";
    before = [ "ntfy-sh.service" ];
    requiredBy = [ "ntfy-sh.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      RuntimeDirectory = "ntfy-sh-auth";
      RuntimeDirectoryMode = "0700";
      RuntimeDirectoryPreserve = true;
      UMask = "0077";
    };
    path = [
      pkgs.mkpasswd
      pkgs.coreutils
    ];
    script = ''
      set -euo pipefail
      token="$(tr -d '\n' < ${config.sops.secrets.ntfy_auth.path})"
      hash="$(printf '%s' "$token" | mkpasswd -m bcrypt -R 10 --stdin)"
      {
        printf "NTFY_AUTH_USERS='%s:%s:admin'\n" "${homelab.username}" "$hash"
        printf "NTFY_AUTH_TOKENS='%s:%s:homelab'\n" "${homelab.username}" "$token"
      } > "$RUNTIME_DIRECTORY/env"
    '';
  };
  systemd.services.ntfy-sh.serviceConfig.EnvironmentFile = "/run/ntfy-sh-auth/env";

  # ZORTEX: notes, calendar, etc.
  services.zortex = {
    enable = true;
    web.port = services.zortex.port;
    web.writable = true;
    web.htmlScripts = true;
    timezone = "America/New_York";
    ntfy.url = "https://${services.ntfy.domain}";
    ntfy.topic = "zortex-notify";
    ntfy.authTokenFile = config.sops.secrets.ntfy_auth.path;
    notesDir = "/srv/sync/personal/notes";
    notesGroup = toString homelab.groups.zortexdata; # "zortexdata"; # lib.toString homelab.groups.personaldata;
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
      nodes.pc.ipv4
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
