{ pkgs, ... }:
{

  home = {
    packages =
      with pkgs;
      with nodePackages_latest;
      with libsForQt5;
      [
        i3
        sway

        # gui
        blueberry
        (mpv.override { scripts = [ mpvScripts.mpris ]; })
        d-spy
        dolphin
        figma-linux
        kolourpaint
        github-desktop
        nautilus # gnome
        icon-library
        dconf-editor # gnome
        qt5.qtimageformats
        vlc
        yad
        okular
        zathura
        # reaper
        tor-browser-bundle-bin
        (google-chrome.override {
          commandLineArgs = [
            "--enable-features=UseOzonePlatform"
            "--ozone-platform=wayland"
          ];
        })

        # tools
        bat
        eza
        gojq
        acpi
        libnotify
        killall
        zip
        unzip
        glib
        foot
        starship
        showmethekey
        vscode
        ydotool

        # theming tools
        gradience
        gnome-tweaks

        # hyprland
        brightnessctl
        cliphist
        fuzzel
        grim
        hyprpicker
        tesseract
        # imagemagick
        pavucontrol
        playerctl
        swappy
        swaylock-effects
        swayidle
        slurp
        swww
        wayshot
        wlsunset
        wl-clipboard
        wf-recorder

        # wayvnc

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
