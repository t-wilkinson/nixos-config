{ pkgs, ... }:
{
  home = {
    packages =
      with pkgs;
      with nodePackages_latest;
      with gnome;
      with libsForQt5;
      [
        # i3 # GAMING

        # GUI
        # blueberry # bluetooth
        # (mpv.override { scripts = [ mpvScripts.mpris ]; })
        # d-spy
        # dolphin
        # github-desktop
        # pkgs.nautilus
        # icon-library
        # pkgs.dconf-editor
        # qt5.qtimageformats
        # vlc
        # yad
        # tor-browser-bundle-bin
        # zathura # document viewer
        # okular # document viewer
        # vscode
        # reaper # conflicts with `jdk`
        # (google-chrome.override {
        #   commandLineArgs =
        #     [ "--enable-features=UseOzonePlatform" "--ozone-platform=wayland" ];
        # })
        # kdePackages.dolphin

        # THEMING TOOLS
        # gradience
        # pkgs.gnome-tweaks

        # HYPRLAND
        brightnessctl
        cliphist
        fuzzel
        grim
        hyprpicker
        tesseract
        imagemagick
        pavucontrol
        playerctl
        swappy
        swaylock-effects
        swayidle
        slurp
        sway
        swww
        wayshot
        wlsunset
        wl-clipboard
        wf-recorder
        wayvnc

        # NODE
        # nodePackages_latest.neovim # error: Alais neovim is still in node-packages.nix
        # vimPlugins.nvim-treesitter.withPlugins
        # neovimUtils.makeNeovim

        # MISC
        # android-file-transfer
        # appimage-run
        # texliveFull

        # (writeShellScriptBin "hello-bro" ''
        #   echo "Hello, ${config.home.username}!"
        # '')
      ];
  };
}
