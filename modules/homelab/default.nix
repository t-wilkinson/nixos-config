# modules/homelab/default.nix
# Options and service implementations, one file per service. The data (nodes, services, ...)
# lives in hosts/inventory.nix; each host sets homelab.thisNode. A service module gates
# on homelab.services.<n>.runsHere; gateway modules gate on homelab.isGateway.
{ ... }:
{
  imports = [
    ./module.nix
    ./storage.nix # volumes, shares, NFS exports/mounts (homelab.storage)
    ./jobs.nix # scheduled jobs report each run to Gatus (homelab.jobs)
    ./status-files.nix # status JSON the dashboard displays (backups, security)

    # Gateway (Pi): proxy, DNS, tunnel, subnet router, NFS exports, fail2ban
    ./caddy.nix
    ./blocky.nix
    ./cloudflared.nix
    ./tailscale.nix
    ./nfs.nix
    ./fail2ban.nix # bans in Caddy and at Cloudflare, ban notifications, dashboard unban

    # Services (each runs on the node named by its `host`)
    ./authelia.nix
    ./dashboard.nix
    ./vaultwarden.nix
    ./ntfy.nix
    ./zortex.nix
    ./syncthing.nix
    ./pastebin.nix
    ./mealie.nix
    ./actual-budget.nix
    ./wakeonlan.nix
    ./mc-server.nix
    ./monitoring.nix # Glances (off: replaced by Beszel), old Prometheus/Grafana sketch
    ./gatus.nix
    ./beszel.nix
    ./borg.nix
    ./borg-mirror.nix # the Pi's borg repo, copied to the PC
    ./borg-pc.nix # the PC's databases, backed up to the Pi
    ./backup-report.nix # backups.json for the dashboard
    ./nextcloud.nix
    ./immich.nix

    # Old Pi-container versions, kept for reference (Nextcloud and Immich now run on the PC)
    # ./nextcloud-container.nix
    # ./immich-container.nix

    ./status.nix # homelab-status command (+ ntfy-notifying timer on the ntfy node)
  ];
}
