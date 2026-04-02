{ lib, ... }:
{
  # Disable remote-access and virtualization triggers
  services.tailscale.enable = lib.mkForce false;
  services.openssh.enable = lib.mkForce false;
  nix.linux-builder.enable = lib.mkForce false;
  # cromulent.services.podman.enabled = lib.mkForce false;

  # Disable file-syncing (Syncthing)
  home-manager.users.trey.services.syncthing.enable = lib.mkForce false;

  # Clean up networking
  # Remove the custom home.lab resolver that might flag as a "tunnel"
  environment.etc."resolver/home.lab".enable = lib.mkForce false;

  # Disable automated UI tweaks that proctors sometimes flag
  system.defaults.NSGlobalDomain.KeyRepeat = lib.mkForce 2; # Reset to standard
  # system.defaults.dock.autohide = lib.mkForce false; # Don't hide the dock during exams
}
