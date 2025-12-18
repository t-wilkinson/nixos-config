# ============================================================================
# scripts/setup-secrets.sh - Helper script for setting up secrets
# ============================================================================
#!/usr/bin/env bash

set -euo pipefail

print_status() {
  echo -e "\033[0;32m==>\033[0m $1"
}

print_error() {
  echo -e "\033[0;31mError:\033[0m $1"
}

# Check if agenix is installed
if ! command -v agenix &>/dev/null; then
  print_error "agenix not found. Install with: nix-shell -p agenix"
  exit 1
fi

# Check if wireguard tools are installed
if ! command -v wg &>/dev/null; then
  print_error "wireguard-tools not found. Install with: nix-shell -p wireguard-tools"
  exit 1
fi

mkdir -p secrets

print_status "Generating WireGuard keys..."

# Generate Pi keys
if [ ! -f "pi-private.key" ]; then
  wg genkey | tee pi-private.key | wg pubkey >pi-public.key
  print_status "Pi keys generated"
else
  print_status "Pi keys already exist, skipping"
fi

# Generate Desktop keys
if [ ! -f "desktop-private.key" ]; then
  wg genkey | tee desktop-private.key | wg pubkey >desktop-public.key
  print_status "Desktop keys generated"
else
  print_status "Desktop keys already exist, skipping"
fi

# Generate Laptop keys
if [ ! -f "laptop-private.key" ]; then
  wg genkey | tee laptop-private.key | wg pubkey >laptop-public.key
  print_status "Laptop keys generated"
else
  print_status "Laptop keys already exist, skipping"
fi

print_status "Creating encrypted secrets..."

# Encrypt Pi's private key
if [ ! -f "secrets/wireguard-private-key.age" ]; then
  cat pi-private.key | agenix -e secrets/wireguard-private-key.age
  print_status "WireGuard private key encrypted"
fi

# WiFi password
if [ ! -f "secrets/wifi-password.age" ]; then
  read -sp "Enter WiFi password: " wifi_pass
  echo
  echo -n "$wifi_pass" | agenix -e secrets/wifi-password.age
  print_status "WiFi password encrypted"
fi

# Nextcloud admin password
if [ ! -f "secrets/nextcloud-admin-password.age" ]; then
  read -sp "Enter Nextcloud admin password: " nc_pass
  echo
  echo -n "$nc_pass" | agenix -e secrets/nextcloud-admin-password.age
  print_status "Nextcloud password encrypted"
fi

# Vaultwarden admin token
if [ ! -f "secrets/vaultwarden-admin-token.age" ]; then
  token=$(openssl rand -hex 32)
  echo -n "$token" | agenix -e secrets/vaultwarden-admin-token.age
  print_status "Vaultwarden admin token encrypted"
  print_status "Admin token: $token (save this!)"
fi

print_status "All secrets created!"
print_status ""
print_status "Public keys (add these to your configuration):"
echo "  Pi:      $(cat pi-public.key)"
echo "  Desktop: $(cat desktop-public.key)"
echo "  Laptop:  $(cat laptop-public.key)"
print_status ""
print_status "Don't forget to update networking.nix with these public keys!"
