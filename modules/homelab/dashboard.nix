# modules/homelab/dashboard.nix
# Homepage dashboard (LAN/tailnet only), plus extra routes on its site block: the Wake-on-LAN
# hooks and the root certificate download. Tiles are generated from the inventory.
{
  config,
  lib,
  ...
}:
let
  homelab = config.homelab;
  services = homelab.services;
  net = homelab.network;
  nodes = homelab.nodes;
  cfg = services.dashboard;

  # One tile per enabled service with a dashboard category (inventory.nix: name, description,
  # dashboard.{category,icon,extra}). Groups appear in groupOrder, then any others.
  mkTile = service: {
    ${service.name} = {
      icon = service.dashboard.icon;
      href = "https://${service.domain}";
      description = service.description;
    }
    // service.dashboard.extra;
  };
  tiled = lib.filterAttrs (
    n: s: s.enable && s.expose && s.dashboard.category != null && n != "dashboard"
  ) services;
  categories = lib.unique (lib.mapAttrsToList (n: s: s.dashboard.category) tiled);

  # Extras that aren't services
  extraTiles = {
    "Infrastructure" = [
      {
        "Blocky DNS" = {
          icon = "mdi-dns";
          href = "http://${nodes.${homelab.gateway}.ipv4}:4000"; # If you enable Blocky's HTTP port
          description = "Ad-blocking & Local DNS";
        };
      }
      {
        "Root Certificate" = {
          icon = "mdi-file-certificate";
          href = "https://${cfg.domain}/root.crt";
          description = "Trust local HTTPS";
        };
      }
    ];
    # Wake / sleep buttons (handled by customJS below) for each wakeOnLan node
    "Compute Nodes" = lib.optionals services.wakeonlan.enable (
      lib.concatLists (
        lib.mapAttrsToList (n: node: [
          {
            "${node.name} (WOL)" = {
              icon = "mdi-power";
              href = "#wake-${n}";
              description = "Send magic packet";
              # ping = node.ipv4;
            };
          }
          {
            "${node.name} (Sleep)" = {
              icon = "mdi-power-sleep";
              href = "#sleep-${n}";
              description = "Suspend";
            };
          }
        ]) (lib.filterAttrs (n: node: node.wakeOnLan) nodes)
      )
    );
  };
  groupOrder = [
    "Applications"
    "Infrastructure"
    "Compute Nodes"
  ];
  homepageGroups = map (group: {
    ${group} =
      lib.mapAttrsToList (n: s: mkTile s) (lib.filterAttrs (n: s: s.dashboard.category == group) tiled)
      ++ (extraTiles.${group} or [ ]);
  }) (groupOrder ++ lib.subtractLists groupOrder categories);

  mkHomepageEntry = name: service: {
    ${name} = {
      description = service.description;
      href = "https://${service.domain}";
    };
  };
in
{
  config = lib.mkMerge [
    {
      # Per-service additions to the generated Caddy site block (run inside `route`, in order)
      homelab.services.dashboard.extraConfig = ''
        # Wake-on-LAN hooks (the dashboard itself is LAN/tailnet only). Sleep hooks for each node
        # are added before this by wakeonlan.nix.
        ${lib.optionalString services.wakeonlan.enable ''
          handle /hooks/* {
            reverse_proxy ${services.wakeonlan.localEndpoint}
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
    }

    (lib.mkIf cfg.runsHere {
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

        widgets =
          # Glances is off (Beszel replaced it); the built-in resources widget shows this host
          lib.optional services.glances.enable {
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
          ++ lib.optional (!services.glances.enable) {
            resources = {
              cpu = true;
              memory = true;
              disk = [
                "/"
                "/srv/backup"
              ];
              cputemp = true;
              uptime = true;
            };
          }
          ++ [
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

        # Tiles come from the inventory (homelab.services.<n>.dashboard), plus extraTiles above
        services = homepageGroups;

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

        # Buttons with href "#wake-<node>" / "#sleep-<node>" call /hooks/<action>-<node> (Caddy routes
        # wake to the Pi's webhook, sleep to the node's own)
        customJS = ''
          document.addEventListener('click', async (e) => {
            const link = e.target.closest('a[href^="#wake-"], a[href^="#sleep-"]');
            if (!link) return;

            e.preventDefault();
            e.stopPropagation();

            const hook = link.getAttribute('href').slice(1);
            if (hook.startsWith('sleep-') && !confirm(`Suspend ''${hook.slice(6)}?`)) return;

            link.style.opacity = '0.5';

            try {
              const res = await fetch(`/hooks/''${hook}`);
              const responseText = (await res.text()).trim();

              if (res.ok) {
                alert(`Success (''${res.status}):\n''${responseText || 'done'}`);
              } else {
                alert(`Failed (''${res.status}):\n''${responseText}`);
              }
            } catch (err) {
              alert(`Error triggering ''${hook}:\n''${err.message}`);
            } finally {
              link.style.opacity = '1';
            }
          });
        '';

      };
    })
  ];
}
