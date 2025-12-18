# ============================================================================
# laptop-config.nix - Configuration snippet for laptop nix-darwin
# ============================================================================
{
  config,
  pkgs,
  lib,
  ...
}:

{
  # WireGuard client for laptop
  # Note: nix-darwin uses different syntax

  # For macOS, you'll need to configure WireGuard manually or use:
  homebrew.casks = [ "wireguard-tools" ];

  # Create WireGuard config file
  system.activationScripts.postActivation.text = ''
    mkdir -p /usr/local/etc/wireguard
    cat > /usr/local/etc/wireguard/wg0.conf <<EOF
    [Interface]
    PrivateKey = YOUR_LAPTOP_PRIVATE_KEY
    Address = 10.0.1.3/24

    [Peer]
    PublicKey = PI_PUBLIC_KEY
    Endpoint = YOUR_HOME_IP:51820
    AllowedIPs = 10.0.0.0/16
    PersistentKeepalive = 25
    EOF
  '';

  # Install Caddy CA certificate
  # For macOS, manually add the certificate to Keychain:
  # 1. Download from http://10.0.1.1:8888/root.crt
  # 2. Open Keychain Access
  # 3. Import the certificate and trust it for SSL
}
