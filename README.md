# NixOS Config

Make sure to run the following:

```bash
chmod +x ./homes/<user>/.config/ags/scripts/color_generation/{applycolor.sh,colorgen.sh,switchcolor.sh,switchwall.sh,generate_colors_material.py}

IMPURITY_PATH=$(pwd) sudo --preserve-env=IMPURITY_PATH nixos-rebuild switch --flake . --impure
```

## macOS

Install nix from [determinate systems](https://determinate.systems/) `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install` because normal installation via nixos.org installer is difficult to remove. Make sure to say "No" to installing Determinate Nix.

## Important tools

- https://github.com/nix-darwin/nix-darwin provides nix modules (/etc/nixos/configuration.nix) for macOS.
