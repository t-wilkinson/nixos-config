# NixOS Config

Make sure to run the following:

```bash
chmod +x ./homes/<user>/.config/ags/scripts/color_generation/{applycolor.sh,colorgen.sh,switchcolor.sh,switchwall.sh,generate_colors_material.py}

IMPURITY_PATH=$(pwd) sudo --preserve-env=IMPURITY_PATH nixos-rebuild switch --flake . --impure
```

### Make apps executable

```bash
find apps/$(uname -m | sed 's/arm64/aarch64/')-darwin -type f \( -name apply -o -name build -o -name build-impure -o -name build-switch -o -name build-switch-impure -o -name create-keys -o -name copy-keys -o -name check-keys -o -name rollback \) -exec chmod +x {} \;
```

## macOS

Install nix from [determinate systems](https://determinate.systems/) `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install` because normal installation via nixos.org installer is difficult to remove. Make sure to say "No" to installing Determinate Nix.

## Important tools

- https://github.com/nix-darwin/nix-darwin provides nix modules (/etc/nixos/configuration.nix) for macOS.

## Import Layout

- flake.nix
  - modules/hosts/{HOST}
    - modules/hosts/{HOST}/home-manager
    - modules/shared
      - modules/home-manager

## TODO:

Run scripts like this when first installing or indempotently? `rustup default nightly`
