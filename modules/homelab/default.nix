# modules/homelab/default.nix
# Options and service implementations. The data (nodes, services, ...) lives in
# hosts/homelab/inventory.nix; each host sets homelab.thisNode.
{ ... }:
{
  imports = [
    ./module.nix

    ./mc-server.nix
    ./monitoring.nix
    ./borg.nix
    ./syncthing.nix
    ./mealie.nix
    ./actual-budget.nix
    ./wakeonlan.nix

    # Old Pi-container versions; Nextcloud and Immich now run on the PC (hosts/nixos/{nextcloud,immich}.nix)
    # ./nextcloud.nix
    # ./immich.nix
    ./pastebin.nix
  ];
}
