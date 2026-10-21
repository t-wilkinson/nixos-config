# hosts/nixos/home-manager/shell.nix
#
# Desktop shell (Quickshell, config/quickshell) and wallpaper-driven colors (matugen,
# config/matugen). Both directories are linked live from the repo (default.nix).
#
#   theme-wallpaper IMAGE   set the wallpaper and recolor everything (Ctrl+Super+T: pick one)
#   theme-wallpaper DIR     a random image from DIR
#   THEME_MODE=light theme-wallpaper IMAGE   light scheme
#
# Generated colors live in ~/.local/state/theme/ (see config/matugen/config.toml for which
# app reads which file). The old AGS shell is still installed: `pkill -x quickshell; run_ags`.
{ pkgs, lib, ... }:
let
  matugenConfig = "$HOME/.config/matugen/config.toml";
  defaultColor = "#7db7e0"; # used until the first wallpaper is set

  theme-wallpaper = pkgs.writeShellApplication {
    name = "theme-wallpaper";
    runtimeInputs = with pkgs; [
      matugen
      awww
      yad
      libnotify
      coreutils
      findutils
      procps
      glib # gsettings, for the GTK reload hook
    ];
    text = ''
      state="$HOME/.local/state/theme"
      mkdir -p "$state"

      target="''${1:-}"
      if [ -z "$target" ]; then
        dir="$HOME/Pictures/Wallpapers"
        [ -d "$dir" ] || dir="$HOME/Pictures"
        target=$(cd "$dir" && yad --width 1200 --height 800 --file --add-preview --large-preview \
          --title='Choose wallpaper') || exit 0
      fi
      if [ -d "$target" ]; then
        target=$(find "$target" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | shuf -n 1)
      fi
      if [ ! -f "$target" ]; then
        echo "theme-wallpaper: no image: $target" >&2
        exit 1
      fi

      # matugen sets the wallpaper (awww, config.toml) and writes every template.
      # --source-color-index 0: take the most prominent color instead of asking.
      matugen image "$target" --source-color-index 0 --mode "''${THEME_MODE:-dark}" -c "${matugenConfig}"
      realpath "$target" > "$state/wallpaper"
      notify-send -a Theme -i "$target" "Wallpaper and colors updated" "$(basename "$target")" || true
    '';
  };
in
{
  home.packages = [
    pkgs.quickshell # `qs` / `quickshell`
    pkgs.matugen
    theme-wallpaper
  ];

  # First switch: generate a default theme so every app has its color file (kitty, fuzzel,
  # Hyprland and GTK include/source/import it). Later wallpapers overwrite it.
  home.activation.themeDefaults = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [ ! -e "$HOME/.local/state/theme/colors.json" ] && [ -e "${matugenConfig}" ]; then
      run ${pkgs.matugen}/bin/matugen color hex "${defaultColor}" -c "${matugenConfig}" -q || true
    fi
  '';
}
