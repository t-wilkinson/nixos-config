# modules/homelab/status.nix
#
# `homelab-status`: one command that checks this node's part of the homelab. The checks are
# generated from the inventory, so a new service is checked as soon as it is added there:
#   - systemd units of every service whose host is this node (homelab.services.<n>.units)
#   - on the proxy node (Caddy): Caddy, Blocky, Tailscale, the Cloudflare tunnel, every exposed
#     service through Caddy on both names, every public service through Cloudflare, and that
#     private services' public names are absent from public DNS
#   - NFS mounts, the borg backup age, disk usage, and whether the other nodes are up
# Services on a node that is asleep (the PC) produce warnings, not failures.
#
# On the node that runs ntfy, a timer runs it every 15 minutes and posts to the "homelab"
# topic when the result changes (failing / passing again).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  hl = config.homelab;
  esc = lib.escapeShellArg;
  me = hl.nodes.${hl.thisNode};

  monitored = lib.filterAttrs (n: s: s.enable && s.monitor) hl.services;
  localServices = lib.filterAttrs (n: s: s.runsHere) monitored;
  exposed = lib.filterAttrs (n: s: s.expose && s.domain != null) monitored;
  public = lib.filterAttrs (n: s: s.isPublic && s.publicDomain != null) exposed;
  private = lib.filterAttrs (n: s: !s.isPublic && s.publicDomain != null) exposed;

  # Address of the node running a service, or "" when it runs here (no "asleep" logic needed)
  remoteIp = s: if s.host == hl.thisNode then "" else toString hl.nodes.${s.host}.ipv4;

  isProxy = config.services.caddy.enable;
  hasTunnel = config.services.cloudflared.enable;
  hasBlocky = config.services.blocky.enable;
  hasTailscale = config.services.tailscale.enable;
  hasBorg = hl.services.borg.runsHere;

  nfsMounts = lib.filterAttrs (mp: fs: fs.fsType == "nfs" || fs.fsType == "nfs4") config.fileSystems;
  nfsServer = fs: builtins.head (lib.splitString ":" fs.device);

  # Data disks worth watching: / plus local mounts under /mnt or /srv, and the backup drive
  dataMounts = lib.attrNames (
    lib.filterAttrs (
      mp: fs:
      (lib.hasPrefix "/mnt/" mp || lib.hasPrefix "/srv/" mp)
      && !(lib.hasInfix ".snapshots" mp)
      && !(builtins.elem fs.fsType [
        "nfs"
        "nfs4"
        "none"
      ])
    ) config.fileSystems
  );
  borgRepo = config.services.borgbackup.jobs.homelab.repo;
  # The filesystem holding the repo: its own mount if it has one, else "-" (a plain directory
  # on /, which check_backup then doesn't require to be a mount point)
  borgMount = lib.findFirst (mp: lib.hasPrefix "${mp}/" "${borgRepo}/") "-" (
    lib.filter (mp: mp != "/") (lib.attrNames config.fileSystems)
  );
  disks = lib.unique ([ "/" ] ++ dataMounts ++ lib.optional (hasBorg && borgMount != "-") borgMount);

  otherNodes = lib.filterAttrs (n: node: n != hl.thisNode && node.ipv4 != null) hl.nodes;
  namesOf = s: [ s.domain ] ++ lib.optional (s.publicDomain != null) s.publicDomain;

  checks = lib.concatLines (
    [ "section ${esc "Services on ${hl.thisNode}"}" ]
    ++ lib.concatLists (
      lib.mapAttrsToList (n: s: map (u: "check_unit ${esc s.name} ${esc u}") s.units) localServices
    )
    ++ lib.optionals isProxy [
      "section 'Proxy, DNS and tunnel'"
      "check_unit Caddy caddy.service"
    ]
    ++ lib.optionals hasBlocky [
      "check_unit Blocky blocky.service"
      "check_lan_dns ${esc hl.services.dashboard.domain}"
    ]
    ++ lib.optional hasTailscale "check_tailscale"
    ++ lib.optional hasTunnel "check_tunnel"
    ++ lib.optionals isProxy (
      [ "section 'Routes from the LAN (through Caddy)'" ]
      ++ lib.concatLists (
        lib.mapAttrsToList (
          n: s: map (d: "check_lan ${esc s.name} ${esc d} ${esc (remoteIp s)}") (namesOf s)
        ) exposed
      )
    )
    ++ lib.optionals (hasTunnel && public != { }) (
      [ "section 'Public routes (through Cloudflare)'" ]
      ++ lib.mapAttrsToList (
        n: s: "check_public ${esc s.name} ${esc s.publicDomain} ${esc (remoteIp s)}"
      ) public
      ++ lib.mapAttrsToList (n: s: "check_not_public ${esc s.publicDomain}") private
    )
    ++ [ "section 'Storage'" ]
    ++ lib.mapAttrsToList (
      mp: fs: "check_nfs ${esc "NFS ${mp}"} ${esc mp} ${esc (nfsServer fs)}"
    ) nfsMounts
    ++ lib.optional hasBorg "check_backup ${esc borgRepo} ${esc borgMount} ${esc config.sops.secrets.borg_pass.path}"
    ++ map (d: "check_disk ${esc d}") disks
    ++ lib.optionals (otherNodes != { }) (
      [ "section 'Nodes'" ] ++ lib.mapAttrsToList (n: node: "check_node ${esc n} ${esc node.ipv4}") otherNodes
    )
  );

  homelab-status = pkgs.writeShellApplication {
    name = "homelab-status";
    runtimeInputs =
      with pkgs;
      [
        coreutils
        curl
        dnsutils
        iputils
        jq
        systemd
        util-linux
      ]
      ++ lib.optional hasBorg config.services.borgbackup.package
      ++ lib.optional hasTailscale config.services.tailscale.package;
    text = ''
      LAN_IP=${esc (toString me.ipv4)}
    ''
    + builtins.readFile ./status-lib.sh
    + checks
    + ''
      finish
    '';
  };

  notify = hl.services.ntfy.runsHere && config.sops.templates ? "ntfy-auth-header";
in
{
  config = lib.mkMerge [
    {
      # Units per service (checked on the service's host). Unconditional: a definition of
      # homelab.services.* can't depend on runsHere. Override per service in the inventory.
      homelab.services = lib.mapAttrs (n: units: { units = lib.mkDefault units; }) {
        ntfy = [ "ntfy-sh.service" ];
        vault = [ "vaultwarden.service" ];
        dashboard = [ "homepage-dashboard.service" ];
        syncthing = [ "syncthing.service" ];
        zortex = [ "zortex-web.service" ];
        glances = [ "glances.service" ];
        pastebin = [ "microbin.service" ];
        mealie = [ "container@mealie.service" ];
        actual-budget = [ "container@actual-budget.service" ];
        wakeonlan = [ "webhook.service" ];
        auth = [ "authelia-main.service" ];
        gatus = [ "gatus.service" ];
        beszel = [ "beszel-hub.service" ];
        borg = [ "borgbackup-job-homelab.timer" ];
        borg-mirror = [ "borg-mirror.timer" ];
        borg-pc = [ "borgbackup-job-pc.timer" ];
        nextcloud = [
          "phpfpm-nextcloud.service"
          "nginx.service"
          "postgresql.service"
          "redis-nextcloud.service"
        ];
        immich = [ "immich-server.service" ];
        mc-server = [ "container@mc-server.service" ];
      };
    }

    {
      environment.systemPackages = [ homelab-status ];

      # Catch a renamed unit at evaluation time instead of as a permanent false failure
      warnings = lib.concatLists (
        lib.mapAttrsToList (
          n: s:
          map (u: "homelab-status: ${n} lists unit ${u}, which this system does not define") (
            lib.filter (
              u:
              let
                base = lib.removeSuffix ".service" (lib.removeSuffix ".timer" u);
              in
              !(config.systemd.services ? ${base} || config.systemd.timers ? ${base})
            ) s.units
          )
        ) localServices
      );
    }

    (lib.mkIf notify {
      systemd.services.homelab-status = {
        description = "Homelab status check (notifies ntfy when the result changes)";
        serviceConfig = {
          Type = "oneshot";
          StateDirectory = "homelab-status";
        };
        path = [
          homelab-status
          pkgs.curl
          pkgs.coreutils
        ];
        script = ''
          rc=0
          out="$(homelab-status --quiet --no-color 2>&1)" || rc=$?
          printf '%s\n' "$out"
          prev="$(cat "$STATE_DIRECTORY/last" 2> /dev/null || echo 0)"
          echo "$rc" > "$STATE_DIRECTORY/last"
          if [ "$rc" != 0 ] && [ "$prev" = 0 ]; then
            title="Homelab check failing" prio=high tags=rotating_light
          elif [ "$rc" = 0 ] && [ "$prev" != 0 ]; then
            title="Homelab check passing again" prio=default tags=white_check_mark
          else
            exit 0
          fi
          curl -sS -H @${config.sops.templates."ntfy-auth-header".path} \
            -H "Title: $title" -H "Priority: $prio" -H "Tags: $tags" \
            --data-binary "''${out:-All checks passing.}" \
            http://${hl.services.ntfy.localEndpoint}/homelab || true
        '';
      };
      systemd.timers.homelab-status = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5min";
          OnUnitActiveSec = "15min";
        };
      };
    })
  ];
}
