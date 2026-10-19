# modules/homelab/default.nix
# Options and service implementations, one file per service. The data (nodes, services, ...)
# lives in hosts/inventory.nix; each host sets homelab.thisNode. A service module gates
# on homelab.services.<n>.runsHere; gateway modules gate on homelab.isGateway.
{ ... }:
{
  imports = [
    ./module.nix

    # Gateway (Pi): proxy, DNS, tunnel, subnet router, NFS exports, fail2ban
    ./caddy.nix
    ./blocky.nix
    ./cloudflared.nix
    ./tailscale.nix
    ./nfs.nix
    ./fail2ban.nix

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
    ./phone-archive.nix # phone dumps on the PC; the oldest 200 GB copied to the Pi's SSD
    ./nextcloud.nix
    ./immich.nix

    # Old Pi-container versions, kept for reference (Nextcloud and Immich now run on the PC)
    # ./nextcloud-container.nix
    # ./immich-container.nix

    ./status.nix # homelab-status command (+ ntfy-notifying timer on the ntfy node)
  ];
}
