# ============================================================================
# scripts/deploy.sh - Deployment helper script
# ============================================================================
#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
  echo -e "${GREEN}==>${NC} $1"
}

print_error() {
  echo -e "${RED}Error:${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}Warning:${NC} $1"
}

# Check if we're deploying to Pi or building image
TARGET="${1:-pi}"

case "$TARGET" in
"image")
  print_status "Building SD card image..."
  nix build .#images.rpi4
  print_status "Image built successfully!"
  print_status "Flash with: sudo dd if=result/sd-image/homelab-rpi4.img of=/dev/sdX bs=4M status=progress"
  ;;

"pi")
  print_status "Deploying to Raspberry Pi..."

  # Check if Pi is reachable
  if ! ping -c 1 10.0.0.1 &>/dev/null; then
    print_error "Cannot reach Pi at 10.0.0.1"
    print_warning "Make sure the ethernet cable is connected"
    exit 1
  fi

  print_status "Building configuration..."
  nixos-rebuild switch \
    --flake .#homelab-pi \
    --target-host admin@10.0.0.1 \
    --use-remote-sudo \
    --fast

  print_status "Deployment complete!"
  ;;

"check")
  print_status "Checking configuration..."
  nix flake check
  print_status "Configuration is valid!"
  ;;

"update")
  print_status "Updating flake inputs..."
  nix flake update
  print_status "Inputs updated! Run '$0 pi' to deploy"
  ;;

*)
  echo "Usage: $0 {image|pi|check|update}"
  echo ""
  echo "Commands:"
  echo "  image   - Build SD card image"
  echo "  pi      - Deploy to Raspberry Pi"
  echo "  check   - Validate configuration"
  echo "  update  - Update flake inputs"
  exit 1
  ;;
esac
