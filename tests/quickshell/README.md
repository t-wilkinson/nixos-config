# Quickshell config check

Loads `config/quickshell` in a real QML engine with stand-ins for Quickshell's types
(`mods/`), opens and closes each panel, and prints every QML warning or error. It catches
broken property names, bad assignments and JavaScript errors before you deploy. It does not
test real Wayland, Hyprland, PipeWire or D-Bus behavior.

    nix shell nixpkgs#python3Packages.pyside6 -c python3 tests/quickshell/run.py config/quickshell

It also scrolls on the bar (top edge, left and right halves, over the workspaces) and drives
the brightness code: the `Process` stand-in answers `ddcutil` and `brightnessctl` with canned
output and logs each command, so the log shows what would run. Set
`HARNESS_SCREENSHOT=bar.png` to save an image of the bar (install the Material Symbols
Rounded font for icons).

`0 warnings/errors` at the end means the shell loaded cleanly. When the shell starts using a
new Quickshell type or property, add it to the matching stand-in in `mods/`.
