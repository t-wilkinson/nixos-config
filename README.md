# NixOS Config

Make sure to run the following:

```bash
chmod +x ./homes/<user>/.config/ags/scripts/color_generation/{applycolor.sh,colorgen.sh,switchcolor.sh,switchwall.sh,generate_colors_material.py}

IMPURITY_PATH=$(pwd) sudo --preserve-env=IMPURITY_PATH nixos-rebuild switch --flake . --impure
```
