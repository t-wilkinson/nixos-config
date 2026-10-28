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
  files = homelab.statusFiles;

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
  extraTilesBase = {
    "Infrastructure" = [
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
  # Health: status JSON written on the gateway (status-files.nix), read by Homepage's widgets
  # over loopback. Each tile shows a few fields; the Security tile opens the panel in
  # dashboard/security.js.
  backupTile = id: name: description: {
    "${name} backup" = {
      icon = "mdi-backup-restore";
      href = "https://${services.gatus.domain}";
      inherit description;
      widget = {
        type = "customapi";
        url = "${files.url}/backups.json";
        refreshInterval = 60000;
        mappings = [
          {
            field = "repos.${id}.statusText";
            label = "Status";
          }
          {
            field = "repos.${id}.added";
            label = "Added";
            format = "bytes";
          }
          {
            field = "repos.${id}.size";
            label = "Repo";
            format = "bytes";
          }
          {
            field = "repos.${id}.archives";
            label = "Archives";
            format = "number";
          }
        ];
      };
    };
  };
  healthTiles = lib.optionals files.enable (
    lib.optional homelab.bans.enable {
      "Security" = {
        icon = "mdi-shield-lock";
        href = "#security";
        description = "Bans & failed logins";
        widget = {
          type = "customapi";
          url = "${files.url}/security.json";
          refreshInterval = 30000;
          mappings = [
            {
              field = "summary.activeBans";
              label = "Banned";
              format = "number";
            }
            {
              field = "summary.attempts24h";
              label = "Failed (24h)";
              format = "number";
            }
            {
              field = "summary.lastBanText";
              label = "Last ban";
            }
          ];
        };
      };
    }
    ++ lib.optional services.borg.enable (backupTile "homelab" "Pi" "Pi state, nightly")
    ++ lib.optional services.borg-pc.enable (backupTile "pc" "PC" "PC databases & Nextcloud")
    ++ lib.optional (homelab.jobReports.enable && homelab.jobs != { }) {
      "Backup jobs" = {
        icon = "mdi-calendar-check";
        href = "https://${services.gatus.domain}";
        description = "Last run of each job (Gatus)";
        widget = {
          type = "customapi";
          url = "${files.url}/backups.json";
          refreshInterval = 60000;
          display = "list";
          mappings = lib.mapAttrsToList (id: j: {
            field = "jobs.${id}.summary";
            label = j.name;
          }) homelab.jobs;
        };
      };
    }
  );
  extraTiles = extraTilesBase // lib.optionalAttrs (healthTiles != [ ]) { "Health" = healthTiles; };

  groupOrder = [
    "Applications"
    "Health"
    "Infrastructure"
    "Compute Nodes"
  ];
  groupTiles =
    group:
    lib.mapAttrsToList (n: s: mkTile s) (lib.filterAttrs (n: s: s.dashboard.category == group) tiled)
    ++ (extraTiles.${group} or [ ]);
  # Groups with no tiles (e.g. Health before its status files exist) are left out
  homepageGroups = map (group: { ${group} = groupTiles group; }) (
    lib.filter (group: groupTiles group != [ ]) (groupOrder ++ lib.subtractLists groupOrder categories)
  );
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
          title = "Homelab";
          favicon = "https://nixos.org/favicon.ico";
          theme = "dark";
          color = "slate"; # palette is overridden in customCSS; any color works
          headerStyle = "boxed";
          statusStyle = "dot";
          layout = {
            "Applications" = {
              style = "row";
              columns = 3;
              icon = "mdi-apps";
            };
            "Infrastructure" = {
              style = "row";
              columns = 2;
              icon = "mdi-server-network";
            };
            "Compute Nodes" = {
              style = "row";
              columns = 2;
              icon = "mdi-desktop-tower-monitor";
            };
            "Health" = {
              style = "row";
              columns = 2;
              icon = "mdi-heart-pulse";
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
                homelab.storage.shares.pubdrive.localPath
              ];
            };
          }
          ++ lib.optional (!services.glances.enable) {
            resources = {
              cpu = true;
              memory = true;
              # / holds everything on the Pi, /srv/backup included
              disk = [ "/" ];
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

        # Wake/sleep buttons (href "#wake-<node>" / "#sleep-<node>") call /hooks/<action>-<node>; Caddy
        # routes wake to the Pi's webhook, sleep to the node's own. Results show as toasts, not alerts.
        # Also adds a tile count beside each group heading.
        customJS = ''
          (() => {
            // Toasts replace alert(): stacked bottom-right, auto-dismiss after a few seconds
            function toast(kind, title, detail) {
              let box = document.getElementById("z-toasts");
              if (!box) {
                box = document.createElement("div");
                box.id = "z-toasts";
                box.setAttribute("role", "status");
                box.setAttribute("aria-live", "polite");
                document.body.appendChild(box);
              }
              const el = document.createElement("div");
              el.className = `z-toast ''${kind}`;
              el.append(document.createElement("i"));
              const strong = document.createElement("strong");
              strong.textContent = title;
              el.append(strong);
              if (detail) {
                const small = document.createElement("small");
                small.textContent = detail;
                el.append(small);
              }
              box.appendChild(el);
              setTimeout(() => {
                el.classList.add("leaving");
                setTimeout(() => el.remove(), 250);
              }, kind === "fail" ? 8000 : 4500);
            }
            window.zToast = toast; // also used by the Security panel (dashboard/security.js)

            // Buttons with href "#wake-<node>" / "#sleep-<node>" call /hooks/<action>-<node> (Caddy routes
            // wake to the Pi's webhook, sleep to the node's own)
            document.addEventListener("click", async (e) => {
              const link = e.target.closest('a[href^="#wake-"], a[href^="#sleep-"]');
              if (!link) return;

              e.preventDefault();
              e.stopPropagation();

              const hook = link.getAttribute("href").slice(1);
              const [action, ...rest] = hook.split("-");
              const node = rest.join("-");
              const verb = action === "wake" ? "Wake" : "Sleep";
              if (action === "sleep" && !confirm(`Suspend ''${node}?`)) return;

              const card = link.closest(".service-card");
              const setState = (s) => card && (s ? card.setAttribute("data-hook-state", s) : card.removeAttribute("data-hook-state"));
              setState("busy");

              try {
                const res = await fetch(`/hooks/''${hook}`);
                const text = (await res.text()).trim();
                if (res.ok) {
                  setState("ok");
                  toast("ok", `''${verb}: ''${node}`, text || (action === "wake" ? "Magic packet sent" : "Suspending"));
                } else {
                  setState("fail");
                  toast("fail", `''${verb} failed (''${res.status})`, text);
                }
              } catch (err) {
                setState("fail");
                toast("fail", `''${verb} ''${node}: request failed`, err.message);
              }
              setTimeout(() => setState(null), 3000);
            });

            // Tile count beside each group heading
            function countGroups() {
              document.querySelectorAll(".services-group").forEach((group) => {
                const name = group.querySelector(":scope > button .service-group-name");
                const list = group.querySelector(".services-list");
                if (!name || !list) return;
                const n = list.querySelectorAll(":scope > .service").length;
                if (n && name.getAttribute("data-count") !== String(n)) name.setAttribute("data-count", String(n));
              });
            }
            new MutationObserver(countGroups).observe(document.documentElement, { childList: true, subtree: true });
            countGroups();
          })();
        ''
        + lib.optionalString (homelab.bans.enable && files.enable) (builtins.readFile ./dashboard/security.js);

        # Zortex look: warm near-black panels, paper-white text, one orange accent. Retints Homepage's
        # palette variables, then styles groups as panels and tiles as rows with icon chips.
        customCSS = ''
          /* Zortex theme for Homepage
             Tokens mirror Zortex: warm near-black panels, paper-white text, one orange accent.
             Homepage's own utilities live in Tailwind layers, so these unlayered rules win
             without needing !important. */

          /* 1. Retint Homepage's palette so every built-in theme-* utility goes warm */
          html[class*="theme-"] {
            --color-50: 247 245 240;
            --color-100: 236 233 226;
            --color-200: 224 220 211;
            --color-300: 190 186 177;
            --color-400: 146 143 136;
            --color-500: 111 109 104;
            --color-600: 72 73 74;
            --color-700: 42 45 49;
            --color-800: 21 23 26;
            --color-900: 13 14 16;
            --color-logo-start: 150 199 234;
            --color-logo-stop: 106 166 212;

            --z-bg: #15171a;
            --z-panel: #1b1e22;
            --z-raised: #22262b;
            --z-raised-hover: #282c32;
            --z-border: #2c3036;
            --z-border-strong: #3a3f46;
            --z-text: #f2efe8;
            --z-dim: #8f949b;
            --z-accent: #7db7e0;
            --z-accent-soft: rgb(125 183 224 / 0.14);
            --z-accent-line: rgb(125 183 224 / 0.55);
            --z-ok: #6cc38a;
            --z-ok-soft: rgb(108 195 138 / 0.14);
            --z-sleep: #a58be0;
            --z-sleep-soft: rgb(165 139 224 / 0.14);
            --z-bad: #e5675a;
            --z-radius: 12px;
            --z-radius-sm: 8px;
            --z-font: -apple-system, BlinkMacSystemFont, "Segoe UI", Inter, Roboto, Helvetica, Arial, sans-serif;
            --bg-color: 21 23 26;
            --scrollbar-thumb: #3a3f46;
            --scrollbar-track: #15171a;
          }

          /* Zortex's light palette, used if the theme toggle is ever enabled */
          html.light[class*="theme-"] {
            --z-bg: #f7f5f0;
            --z-panel: #fffefb;
            --z-raised: #f3f0e9;
            --z-raised-hover: #ece8df;
            --z-border: #e2ddd2;
            --z-border-strong: #cfc9bc;
            --z-text: #1d2024;
            --z-dim: #6b6f76;
            --z-accent: #2f78ad;
            --z-accent-soft: rgb(47 120 173 / 0.12);
            --z-accent-line: rgb(47 120 173 / 0.5);
            --z-ok: #2f8f55;
            --z-ok-soft: rgb(47 143 85 / 0.12);
            --z-sleep: #6f55b5;
            --z-sleep-soft: rgb(111 85 181 / 0.12);
            --z-bad: #c2463a;
            --bg-color: 247 245 240;
            --scrollbar-thumb: #cfc9bc;
            --scrollbar-track: #f7f5f0;
          }

          /* 2. Page */
          html,
          body {
            background-color: var(--z-bg);
          }
          body {
            color: var(--z-text);
            font-family: var(--z-font);
            -webkit-font-smoothing: antialiased;
          }
          #page_wrapper {
            background:
              radial-gradient(1100px 380px at 50% -160px, var(--z-accent-soft), transparent 70%),
              var(--z-bg);
          }
          ::selection {
            background: var(--z-accent-soft);
            color: var(--z-text);
          }
          :focus-visible {
            outline: 2px solid var(--z-accent);
            outline-offset: 2px;
            border-radius: 6px;
          }

          /* 3. Header bar: widgets in one Zortex panel */
          #information-widgets {
            background: var(--z-panel);
            border: 1px solid var(--z-border);
            border-radius: var(--z-radius);
            box-shadow: 0 12px 32px -18px rgb(0 0 0 / 0.6);
            padding: 8px 18px;
          }
          /* Two rows: date + search on top, the resource strip underneath */
          #widgets-wrap {
            align-items: center;
            column-gap: 16px;
            row-gap: 0;
          }
          #information-widgets-right {
            display: contents;
          }
          #widgets-wrap .information-widget-datetime {
            order: 1;
            flex: 1 1 auto;
            align-items: flex-start;
          }
          #widgets-wrap .information-widget-datetime > div {
            justify-content: flex-start;
          }
          #widgets-wrap .information-widget-search {
            order: 2;
            flex: 0 1 340px;
            min-width: 220px;
          }
          #widgets-wrap > .widget-container:has(.information-widget-resource) {
            order: 3;
            flex: 1 1 100%;
            margin-top: 6px;
            padding-top: 8px;
            border-top: 1px solid var(--z-border);
          }
          #widgets-wrap > .widget-container:has(.information-widget-resource) > div {
            justify-content: flex-start;
            align-self: stretch;
            gap: 2px 26px;
          }


          /* System resources: compact readouts with accent meters, like the Zortex XP meter */
          .information-widget-resource {
            margin-right: 0;
          }
          .information-widget-resource .resource-icon {
            color: var(--z-accent);
            width: 18px;
            height: 18px;
          }
          .information-widget-resource .text-xs {
            font-size: 0.72rem;
            letter-spacing: 0.01em;
            color: var(--z-dim);
          }
          .information-widget-resource .resource-value {
            color: var(--z-text);
            font-weight: 600;
            font-variant-numeric: tabular-nums;
          }
          .resource-usage {
            height: 5px;
            margin-top: 5px;
            border-radius: 999px;
            background: var(--z-border);
            overflow: hidden;
          }
          .resource-usage > div {
            height: 5px;
            border-radius: 999px;
            background: linear-gradient(90deg, rgb(var(--color-logo-stop)), rgb(var(--color-logo-start)));
          }
          /* Flag 90%+ in red. Uptime (the last readout) is a clock, not a load, so it's skipped. */
          .information-widget-resource:not(:last-child) .resource-usage > div[style^="width: 9"]:not([style^="width: 9%"]):not([style^="width: 9."]),
          .information-widget-resource:not(:last-child) .resource-usage > div[style^="width: 100"] {
            background: var(--z-bad);
          }

          /* Search: the Zortex quick-search field */
          .information-widget-search .flex-col.relative {
            height: 36px;
            margin-top: 6px;
            margin-bottom: 6px;
          }
          .information-widget-search input {
            padding-left: 12px;
            font-size: 0.85rem;
            color: var(--z-text);
            background: var(--z-bg);
            border: 1px solid var(--z-border);
            border-radius: var(--z-radius-sm);
            transition: border-color 0.15s ease, box-shadow 0.15s ease;
          }
          .information-widget-search input::placeholder {
            color: var(--z-dim);
          }
          .information-widget-search input:focus {
            outline: none;
            border-color: var(--z-accent-line);
            box-shadow: 0 0 0 3px var(--z-accent-soft);
          }
          .information-widget-search button {
            background: transparent;
            color: var(--z-dim);
          }
          .information-widget-search button svg {
            color: var(--z-dim);
          }
          .information-widget-search [role="listbox"] {
            background: var(--z-panel);
            border-color: var(--z-border);
            color: var(--z-text);
          }

          /* Date/time: the hero readout */
          .information-widget-datetime span {
            color: var(--z-text);
            font-size: 1.4rem;
            font-weight: 650;
            letter-spacing: -0.015em;
          }

          @media (max-width: 640px) {
            #widgets-wrap .information-widget-search {
              flex-basis: 100%;
            }
            .information-widget-datetime span {
              font-size: 1.1rem;
            }
          }

          /* 4. Service groups: each one is a Zortex .panel */
          #layout-groups,
          #services {
            margin-top: 12px;
          }
          .services-group:not(.subgroup) {
            position: relative;
            isolation: isolate;
            padding: 18px 20px 10px;
            margin: 6px 0;
          }
          .services-group:not(.subgroup)::before {
            content: "";
            position: absolute;
            inset: 0 4px;
            z-index: -1;
            background: var(--z-panel);
            border: 1px solid var(--z-border);
            border-radius: var(--z-radius);
          }
          @media (max-width: 640px) {
            .services-group:not(.subgroup) {
              padding: 16px 14px 8px;
            }
          }

          /* Group heading: small and bold, with a dim tile count (set by custom.js) */
          .services-group > button {
            padding: 0 4px;
          }
          .service-group-name {
            align-items: baseline;
            gap: 8px;
            color: var(--z-text);
            font-size: 0.95rem;
            font-weight: 650;
            letter-spacing: 0.01em;
          }
          .service-group-name[data-count]::after {
            content: attr(data-count);
            font-size: 0.72rem;
            font-weight: 500;
            color: var(--z-dim);
            font-variant-numeric: tabular-nums;
          }
          .service-group-icon {
            width: 20px;
            height: 20px;
            margin-right: 10px;
          }
          .service-group-icon > * {
            width: 20px !important;
            height: 20px !important;
          }
          .services-group > button svg {
            color: var(--z-dim);
          }

          /* 5. Service tiles */
          .services-list {
            margin-top: 14px;
            column-gap: 10px;
          }
          .service-card {
            position: relative;
            margin-bottom: 10px;
            padding: 6px;
            color: var(--z-text);
            background: var(--z-raised);
            border: 1px solid var(--z-border);
            border-radius: var(--z-radius-sm);
            box-shadow: none;
            transition: background-color 0.15s ease, border-color 0.15s ease, transform 0.15s ease;
          }
          .service-card:hover {
            color: var(--z-text);
            background: var(--z-raised-hover);
            border-color: var(--z-accent-line);
            transform: translateY(-1px);
          }
          .service-card:active {
            transform: none;
          }
          /* Accent rail on hover, echoing Zortex's focused rows */
          .service-card::before {
            content: "";
            position: absolute;
            left: -1px;
            top: 12px;
            bottom: 12px;
            z-index: 20;
            width: 3px;
            border-radius: 0 3px 3px 0;
            background: var(--z-accent);
            transform: scaleY(0);
            transition: transform 0.18s ease;
          }
          .service-card:hover::before {
            transform: scaleY(1);
          }

          /* Icon chip */
          .service-icon {
            width: 42px;
            height: 42px;
            margin: 2px 4px 2px 2px;
            align-self: center;
            border-radius: 10px;
            background: var(--z-accent-soft);
          }
          .service-icon > * {
            width: 22px !important;
            height: 22px !important;
          }

          .service-name {
            font-size: 0.9rem;
            font-weight: 600;
            line-height: 1.25;
          }
          .service-description {
            margin-top: 3px;
            font-size: 0.76rem;
            color: var(--z-dim);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
          }
          .service-title-text {
            min-width: 0;
          }
          .service-name {
            min-width: 0;
          }

          /* "Opens in a new tab" arrow, shown on hover */
          a.service-title-text::after {
            content: "\2197";
            flex: none;
            margin-right: 12px;
            font-size: 0.85rem;
            color: var(--z-dim);
            opacity: 0;
            transform: translate(-4px, 4px);
            transition: opacity 0.15s ease, transform 0.15s ease, color 0.15s ease;
          }
          .service-card:hover a.service-title-text::after {
            opacity: 1;
            transform: none;
            color: var(--z-accent);
          }

          /* Status dots on tiles */
          .service-tags {
            top: 8px;
            right: 8px;
          }

          /* 6. Compute Nodes: wake / sleep tiles read as actions, not links */
          .service:has(a[href^="#wake-"]) .service-icon {
            background: var(--z-ok-soft);
          }
          .service:has(a[href^="#wake-"]) .service-icon > div {
            background: var(--z-ok) !important;
          }
          .service:has(a[href^="#wake-"]) .service-card:hover {
            border-color: var(--z-ok);
          }
          .service:has(a[href^="#wake-"]) .service-card::before {
            background: var(--z-ok);
          }
          .service:has(a[href^="#sleep-"]) .service-icon {
            background: var(--z-sleep-soft);
          }
          .service:has(a[href^="#sleep-"]) .service-icon > div {
            background: var(--z-sleep) !important;
          }
          .service:has(a[href^="#sleep-"]) .service-card:hover {
            border-color: var(--z-sleep);
          }
          .service:has(a[href^="#sleep-"]) .service-card::before {
            background: var(--z-sleep);
          }
          /* Action pill in place of the external-link arrow */
          .service a[href^="#wake-"].service-title-text::after,
          .service a[href^="#sleep-"].service-title-text::after {
            opacity: 1;
            transform: none;
            padding: 3px 10px;
            font-size: 0.68rem;
            font-weight: 650;
            letter-spacing: 0.05em;
            text-transform: uppercase;
            border: 1px solid var(--z-border-strong);
            border-radius: 999px;
            color: var(--z-dim);
          }
          .service a[href^="#wake-"].service-title-text::after {
            content: "Wake";
          }
          .service a[href^="#sleep-"].service-title-text::after {
            content: "Sleep";
          }
          .service-card:hover a[href^="#wake-"].service-title-text::after {
            color: var(--z-ok);
            border-color: var(--z-ok);
          }
          .service-card:hover a[href^="#sleep-"].service-title-text::after {
            color: var(--z-sleep);
            border-color: var(--z-sleep);
          }
          /* States set by custom.js while a hook runs */
          .service-card[data-hook-state="busy"] {
            opacity: 0.65;
            pointer-events: none;
          }
          .service-card[data-hook-state="busy"] .service-icon {
            animation: z-pulse 1s ease-in-out infinite;
          }
          .service-card[data-hook-state="ok"] {
            border-color: var(--z-ok);
          }
          .service-card[data-hook-state="fail"] {
            border-color: var(--z-bad);
          }
          @keyframes z-pulse {
            50% {
              opacity: 0.35;
            }
          }

          /* 7. Toasts (replace the old alert() popups) */
          #z-toasts {
            position: fixed;
            right: 20px;
            bottom: 20px;
            z-index: 100;
            display: flex;
            flex-direction: column;
            gap: 8px;
            width: min(340px, calc(100vw - 40px));
          }
          .z-toast {
            display: grid;
            grid-template-columns: auto 1fr;
            gap: 2px 10px;
            padding: 11px 14px;
            font-size: 0.82rem;
            color: var(--z-text);
            background: var(--z-panel);
            border: 1px solid var(--z-border);
            border-radius: var(--z-radius-sm);
            box-shadow: 0 14px 34px -14px rgb(0 0 0 / 0.65);
            animation: z-toast-in 0.18s ease-out;
          }
          .z-toast i {
            width: 8px;
            height: 8px;
            margin-top: 5px;
            border-radius: 50%;
            background: var(--z-accent);
          }
          .z-toast.ok i {
            background: var(--z-ok);
          }
          .z-toast.fail i {
            background: var(--z-bad);
          }
          .z-toast strong {
            font-weight: 600;
          }
          .z-toast small {
            grid-column: 2;
            color: var(--z-dim);
            white-space: pre-wrap;
            word-break: break-word;
          }
          .z-toast.leaving {
            opacity: 0;
            transform: translateY(6px);
            transition: opacity 0.2s ease, transform 0.2s ease;
          }
          @keyframes z-toast-in {
            from {
              opacity: 0;
              transform: translateY(8px);
            }
          }

          /* 8. Footer: quiet, like Zortex's stats line */
          #footer {
            padding-top: 16px;
            padding-bottom: 22px;
          }
          #footer,
          #footer * {
            color: var(--z-dim);
          }
          #footer button:hover svg {
            color: var(--z-accent);
          }
          #version {
            font-size: 0.75rem;
          }

          ${lib.optionalString (homelab.bans.enable && files.enable) (builtins.readFile ./dashboard/security.css)}

          @media (prefers-reduced-motion: reduce) {
            *,
            *::before,
            *::after {
              transition: none !important;
              animation: none !important;
            }
          }
        '';
      };
    })
  ];
}
