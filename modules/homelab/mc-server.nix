# modules/homelab/mc-server.nix
#
# Minecraft on the PC: one NixOS container per server (paper, oneblock, atm10; see
# ./minecraft/packs.nix), each running nix-minecraft. They all use port 25565, so only one runs
# at a time: starting one stops the others (Conflicts=), and the choice survives reboots.
#
#   mc-switch                       show what's running
#   sudo mc-switch atm10            switch to a server (or: paper, oneblock, off)
#   sudo mc-switch cmd 'op Trey'    run a console command on the running server
#   journalctl -M mc-atm10 -f       the running server's log
#
# The dashboard does the same with its Minecraft tiles (webhook hooks mc-status and
# mc-switch-<name> on the PC, routed by the Pi's Caddy).
#
# Worlds live on the Pi (shares minecraft, minecraft-oneblock, minecraft-atm10, NFS-mounted
# here), so the Pi's nightly borg backup includes them. Mods and configs come from the Nix store.
# Every server keeps the same RCON port and password, so borg's save-all/save-off works on
# whichever one is up.
{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
let
  homelab = config.homelab;
  cfg = homelab.services.mc-server;
  shares = homelab.storage.shares;
  pc = homelab.nodes.${cfg.host};
  webhookPort = homelab.services.wakeonlan.port; # the PC's webhook (also serves the sleep hook)

  packs = import ./minecraft/packs.nix { inherit lib pkgs; };

  # Per-server settings on top of packs.nix. `properties` are enforced in server.properties on
  # every start; everything else in that file stays as the server or you leave it.
  servers = {
    paper = packs.paper // {
      share = "minecraft";
      jvmOpts = "-Xms4G -Xmx8G";
      properties = { };
      symlinks = { };
      seed = "";
    };

    oneblock = packs.oneblock // {
      share = "minecraft-oneblock";
      jvmOpts = "-Xms2G -Xmx6G";
      properties = {
        level-name = "world";
      };
      symlinks.mods = "${packs.oneblock.serverFiles}/mods";
      seed = ''
        if [ ! -e world/level.dat ]; then
          echo "New OneBlock world from ${packs.oneblock.world}"
          rm -rf world
          cp -r --no-preserve=mode,ownership ${packs.oneblock.world} world
        fi
      '';
    };

    atm10 = packs.atm10 // {
      share = "minecraft-atm10";
      jvmOpts = "-Xms4G -Xmx10G"; # the pack suggests 8G minimum
      properties = {
        allow-flight = "true"; # jetpacks, flying mounts: otherwise players get kicked for flying
      };
      symlinks.mods = "${packs.atm10.files}/mods";
      # First start, and after a pack update: take the pack's config/, defaultconfigs/, kubejs/,
      # ... (replacing yours, as ATM's update guide says). Keep server.properties if there is one.
      seed = ''
        pack=${packs.atm10.files}
        if [ "$(cat .atm10-version 2>/dev/null || true)" != ${packs.atm10.version} ]; then
          echo "Installing ATM10 ${packs.atm10.version} files"
          for src in "$pack"/*; do
            name=$(basename "$src")
            case "$name" in
              mods | startserver.* | *.bat | *.ps1 | user_jvm_args.txt | variables.txt | eula.txt) continue ;;
            esac
            if [ "$name" = server.properties ] && [ -e server.properties ]; then
              continue
            fi
            rm -rf "./$name"
            cp -r --no-preserve=mode,ownership "$src" "./$name"
          done
          echo ${packs.atm10.version} > .atm10-version
        fi
      '';
    };
  };

  ready = lib.filterAttrs (n: s: s.ready) servers;
  names = lib.attrNames ready;
  unit = n: "container@mc-${n}.service";

  # Enforced in server.properties before each start (the server writes the rest itself).
  # The RCON password comes from the environment file, never the Nix store.
  enforcedProperties =
    n: s:
    {
      server-port = toString cfg.port;
      enable-rcon = "true";
      "rcon.port" = toString cfg.data.rconPort;
      "rcon.password" = "$RCON_PASSWORD";
      online-mode = lib.boolToString cfg.data.onlineMode;
      motd = "Wilkinson Homelab - ${s.label}";
    }
    // s.properties;

  startPre = n: s: ''
    : "''${RCON_PASSWORD:?missing from the environment file}"
    ${s.seed}

    set_prop() {
      touch server.properties
      { awk -v k="$1=" 'index($0, k) != 1' server.properties; printf '%s=%s\n' "$1" "$2"; } > server.properties.new
      mv server.properties.new server.properties
    }
    ${lib.concatLines (
      lib.mapAttrsToList (k: v: ''set_prop ${lib.escapeShellArg k} "${v}"'') (enforcedProperties n s)
    )}
  '';

  # The environment file every server reads (RCON_PASSWORD), bind-mounted into the containers
  envFile = config.sops.templates."minecraft-env";

  mkContainer = n: s: {
    autoStart = false; # mc-switch-boot starts the selected one
    privateNetwork = false;
    bindMounts = {
      "/srv/minecraft/${n}" = {
        hostPath = shares.${s.share}.localPath; # the Pi's share, over NFS
        isReadOnly = false;
      };
    }
    // homelab.lib.mkSecretMounts [ envFile ];

    config =
      { pkgs, ... }:
      {
        imports = [ inputs.nix-minecraft.nixosModules.minecraft-servers ];
        nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];
        nixpkgs.config.allowUnfree = true; # the server jars are unfreeRedistributable
        system.stateVersion = homelab.containerStateVersion;

        # The container shares the PC's network; the PC's firewall applies, not this one
        networking.firewall.enable = false;

        # uid 1000 owns the worlds on the Pi (it was the old container's minecraft user, and is
        # trey on both machines). serverdata is the shares' group.
        users.users.minecraft = {
          uid = lib.mkForce 1000;
          extraGroups = [ "serverdata" ];
        };
        users.groups.serverdata.gid = homelab.groups.serverdata;
        # nix-minecraft would make the data directory 0770 minecraft:minecraft; on the share it
        # stays 2775 :serverdata (the first rule for a path wins)
        systemd.tmpfiles.rules = lib.mkBefore [ "d /srv/minecraft/${n} 2775 minecraft serverdata - -" ];

        services.minecraft-servers = {
          enable = true;
          eula = true;
          openFirewall = false; # the PC opens 25565 (hosts/nixos/networking.nix)
          environmentFile = envFile.path;
          # Logs in the journal (journalctl -M mc-<name>), console through a socket
          managementSystem = {
            tmux.enable = false;
            systemd-socket.enable = true;
          };
          servers.${n} = {
            enable = true;
            autoStart = true; # with the container
            restart = "always";
            package = s.package pkgs;
            inherit (s) jvmOpts symlinks;
            path = [ pkgs.gawk ]; # set_prop in extraStartPre
            extraStartPre = startPre n s;
          };
        };
      };
  };

  # Root: record the choice, then start that server (Conflicts= stops the others) or stop all
  switchScript = ''
    target=$1
    case "$target" in
      ${lib.concatStringsSep " | " (names ++ [ "off" ])}) ;;
      *) echo "Unknown server: $target (choose ${lib.concatStringsSep ", " (names ++ [ "off" ])})" >&2; exit 2 ;;
    esac
    echo "$target" > /var/lib/mc-switch/current
    if [ "$target" = off ]; then
      systemctl stop --no-block ${lib.concatMapStringsSep " " unit names}
      echo "Stopping Minecraft"
    else
      systemctl start --no-block "container@mc-$target.service"
      echo "Starting $target"
    fi
  '';

  # Anyone: JSON for the dashboard and `mc-switch`
  status = pkgs.writeShellApplication {
    name = "mc-status";
    runtimeInputs = [
      pkgs.jq
      pkgs.iproute2
      config.systemd.package
    ];
    text = ''
      selected=$(cat /var/lib/mc-switch/current 2>/dev/null || echo ${cfg.data.defaultServer})
      listening=false
      if [ -n "$(ss -Hltn 'sport = :${toString cfg.port}')" ]; then listening=true; fi

      servers='{}'
      running=""
      ${lib.concatLines (
        lib.mapAttrsToList (n: s: ''
          state=$(systemctl is-active ${unit n} || true)
          case "$state" in
            active) if [ "$listening" = true ]; then st=Online; else st=Starting; fi; running=${n} ;;
            activating | reloading) st=Starting; running=${n} ;;
            deactivating) st=Stopping ;;
            failed) st=Failed ;;
            *) st=Off ;;
          esac
          servers=$(jq -c --arg st "$st" '. + {"${n}": {label: ${builtins.toJSON s.label}, status: $st}}' <<< "$servers")
        '') ready
      )}

      summary=Off
      if [ -n "$running" ]; then
        summary=$(jq -r --arg n "$running" '.[$n] | "\(.label) · \(.status)"' <<< "$servers")
      fi
      jq -n --arg selected "$selected" --arg running "$running" --arg summary "$summary" \
        --argjson listening "$listening" --argjson servers "$servers" \
        '{selected: $selected, running: $running, listening: $listening, summary: $summary, servers: $servers}'
    '';
  };

  cli = pkgs.writeShellApplication {
    name = "mc-switch";
    excludeShellChecks = [ "SC2016" ]; # cmd: the inner sh -c script expands its own arguments
    runtimeInputs = [
      pkgs.jq
      pkgs.nixos-container
      config.systemd.package
    ];
    text = ''
      case "''${1:-status}" in
        status)
          ${lib.getExe status} | jq -r '"Selected: \(.selected)", (.servers | to_entries[] | "  \(.key)\t\(.value.status)")'
          ;;
        cmd)
          shift
          running=$(${lib.getExe status} | jq -r .running)
          if [ -z "$running" ]; then
            echo "No Minecraft server is running" >&2
            exit 1
          fi
          # The server reads its console from this socket (nix-minecraft's systemd-socket mode)
          nixos-container run "mc-$running" -- sh -c 'printf "%s\n" "$1" > "/run/minecraft/$2.stdin"' _ "$*" "$running"
          echo "Sent to $running; see journalctl -M mc-$running -u minecraft-server-$running -n 20"
          ;;
        -h | --help)
          echo "usage: mc-switch [status | ${lib.concatStringsSep " | " (names ++ [ "off" ])} | cmd <console command>]"
          ;;
        *)
          systemctl start "mc-switch@$1.service"
          ;;
      esac
    '';
  };

  statusUrl = "http://${pc.ipv4}:${toString webhookPort}/hooks/mc-status";

  # Client modpacks the dashboard offers for download (dash.home.lab/minecraft/<file>)
  clientPacks = lib.optionalAttrs packs.oneblock.ready {
    "oneblock.mrpack" = {
      label = "OneBlock client pack";
      description = "Import in the Modrinth App or Prism Launcher";
      file = packs.oneblock.mrpack;
    };
  };
  clientPackDir = pkgs.linkFarm "minecraft-client-packs" (
    lib.mapAttrsToList (name: p: {
      inherit name;
      path = p.file;
    }) clientPacks
  );
in
{
  config = lib.mkMerge [
    {
      homelab.services.mc-server = {
        port = lib.mkDefault 25565;
        monitor = lib.mkDefault false; # one of several servers (or none) runs, by choice
        data = {
          rconPort = lib.mkDefault 25575;
          defaultServer = lib.mkDefault "paper"; # until a choice is made
          # online-mode=false: anyone who reaches the port can join as any name, so keep the
          # port off the internet (LAN/tailnet only) while this is false
          onlineMode = lib.mkDefault false;
          # For the dashboard (on the Pi)
          servers = lib.mapAttrs (n: s: { inherit (s) label description icon; }) ready;
          inherit statusUrl;
          inherit clientPacks;
        };
      };

      # The Pi: route the hooks to the PC and serve the client packs. The condition sits inside
      # the value: an mkIf around homelab.services would need homelab.services to decide it.
      homelab.services.dashboard.extraConfig = lib.mkIf (cfg.enable && homelab.isGateway) (
        lib.mkBefore ''
          handle /hooks/mc-* {
            reverse_proxy ${pc.ipv4}:${toString webhookPort}
          }
          ${lib.optionalString (clientPacks != { }) ''
            handle_path /minecraft/* {
              root * ${clientPackDir}
              header Content-Disposition attachment
              file_server
            }
          ''}
        ''
      );

      warnings = lib.optionals cfg.enable (
        lib.concatLists (
          lib.mapAttrsToList (
            n: s: map (msg: "Minecraft server ${n} is off until you ${msg}") (s.notReady or [ ])
          ) servers
        )
      );
    }

    (lib.mkIf cfg.runsHere {
      assertions = [
        {
          assertion = ready ? ${cfg.data.defaultServer};
          message = "homelab.services.mc-server.data.defaultServer (${cfg.data.defaultServer}) is not a ready server: ${toString names}";
        }
      ];

      # RCON_PASSWORD for every server (borg on the Pi uses the same secret)
      sops.secrets.minecraft_rcon_pass.sopsFile = homelab.lib.secretsFile;
      sops.templates."minecraft-env".content = ''
        RCON_PASSWORD=${config.sops.placeholder.minecraft_rcon_pass}
      '';

      containers = lib.mapAttrs' (n: s: lib.nameValuePair "mc-${n}" (mkContainer n s)) ready;

      systemd.services =
        lib.mapAttrs' (
          n: s:
          lib.nameValuePair "container@mc-${n}" {
            conflicts = map unit (lib.remove n names);
          }
        ) ready
        // {
          "mc-switch@" = {
            description = "Switch the Minecraft server to %i";
            path = [ config.systemd.package ];
            scriptArgs = "%i";
            script = switchScript;
            serviceConfig = {
              Type = "oneshot";
              StateDirectory = "mc-switch";
              StateDirectoryMode = "0755"; # mc-status (webhook user) reads the choice
            };
          };

          mc-switch-boot = {
            description = "Start the selected Minecraft server";
            wantedBy = [ "multi-user.target" ];
            wants = [ "network-online.target" ];
            after = [
              "network-online.target"
              "remote-fs.target"
            ];
            path = [ config.systemd.package ];
            script = ''
              selected=$(cat /var/lib/mc-switch/current 2>/dev/null || echo ${cfg.data.defaultServer})
              case "$selected" in
                ${lib.concatStringsSep " | " names}) systemctl start --no-block "container@mc-$selected.service" ;;
                *) echo "Minecraft: nothing to start ($selected)" ;;
              esac
            '';
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              StateDirectory = "mc-switch";
              StateDirectoryMode = "0755";
            };
          };
        };

      environment.systemPackages = [
        cli
        status
        pkgs.mcrcon
      ];

      # Dashboard hooks, next to the sleep hook (wakeonlan.nix). Switching is a POST with header
      # X-Homelab-Action: mc-switch: a header other sites can't send without a CORS preflight,
      # which webhook doesn't answer (same as the unban hook, fail2ban.nix).
      services.webhook = {
        enable = true;
        port = lib.mkDefault webhookPort;
        hooks = {
          mc-status = {
            execute-command = lib.getExe status;
            include-command-output-in-response = true;
            include-command-output-in-response-on-error = true;
            response-headers = [
              {
                name = "Content-Type";
                value = "application/json";
              }
              {
                name = "Cache-Control";
                value = "no-store";
              }
            ];
          };
        }
        // lib.listToAttrs (
          map (
            n:
            lib.nameValuePair "mc-switch-${n}" {
              execute-command = "${config.systemd.package}/bin/systemctl";
              pass-arguments-to-command = [
                {
                  source = "string";
                  name = "start";
                }
                {
                  source = "string";
                  name = "mc-switch@${n}.service";
                }
              ];
              http-methods = [ "POST" ];
              trigger-rule.match = {
                type = "value";
                value = "mc-switch";
                parameter = {
                  source = "header";
                  name = "X-Homelab-Action";
                };
              };
              trigger-rule-mismatch-http-response-code = 400;
              include-command-output-in-response = true;
              include-command-output-in-response-on-error = true;
            }
          ) (names ++ [ "off" ])
        );
      };
      networking.firewall.interfaces.${pc.lanInterface}.allowedTCPPorts = [ webhookPort ];

      security.polkit.extraConfig = ''
        // homelab: the webhook user may switch the Minecraft server, nothing else
        polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.systemd1.manage-units" &&
              subject.user == "${config.services.webhook.user}" &&
              action.lookup("verb") == "start" &&
              /^mc-switch@(${lib.concatStringsSep "|" (names ++ [ "off" ])})\.service$/.test(action.lookup("unit"))) {
            return polkit.Result.YES;
          }
        });
      '';
    })
  ];
}
