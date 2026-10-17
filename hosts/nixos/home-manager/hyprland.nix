{ pkgs, ... }:
let
  # nixpkgs' Hyprland (0.55 on 26.05), the same one greetd starts. The flake's hyprland input
  # was pinned to v0.40 (2024), so this launcher ran a different Hyprland from the session.
  hyprland = pkgs.hyprland;
  # plugins = pkgs.hyprlandPlugins; # hyprexpo, hyprbars, ... built against this Hyprland

  launcher = pkgs.writeShellScriptBin "hypr" ''
    #!/${pkgs.bash}/bin/bash

    export WLR_NO_HARDWARE_CURSORS=1
    export _JAVA_AWT_WM_NONREPARENTING=1

    exec ${hyprland}/bin/Hyprland
  '';
in
{
  home.packages = with pkgs; [
    launcher
    # adoptopenjdk-jre-bin
    temurin-jre-bin
  ];

  xdg.desktopEntries."org.gnome.Settings" = {
    name = "Settings";
    comment = "Gnome Control Center";
    icon = "org.gnome.Settings";
    exec = "env XDG_CURRENT_DESKTOP=gnome ${pkgs.gnome-control-center}/bin/gnome-control-center";
    categories = [ "X-Preferences" ];
    terminal = false;
  };

  programs = {
    swaylock = {
      enable = true;
      package = pkgs.swaylock-effects;
    };
  };
}
