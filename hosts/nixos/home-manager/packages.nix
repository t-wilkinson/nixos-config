{ pkgs, unstable, ... }:
{

  home = {
    packages =
      with pkgs;
      [
        i3
        sway
        pinentry
        foot
        bitwarden-desktop
        bitwarden-cli
        gimp

        # VIRTUALIZATION
        k3s
        incus
        docker

        # GUI
        kdePackages.okular # pdf viewer
        # zathura # pdf viewer
        blueberry
        (mpv.override { scripts = [ mpvScripts.mpris ]; })
        d-spy
        kdePackages.dolphin
        nautilus # gnome
        icon-library
        dconf-editor # gnome
        libsForQt5.qt5.qtimageformats
        yad
        # tor-browser-bundle-bin
        (google-chrome.override {
          commandLineArgs = [
            "--enable-features=UseOzonePlatform"
            "--ozone-platform=wayland"
          ];
        })
        # chromedriver
        easyeffects

        # tools
        libnotify
        showmethekey
        # vscode
        ydotool # simulate mouse and keyboard

        # theming tools
        gradience
        gnome-tweaks

        # hyprland
        hyprland
        brightnessctl
        cliphist
        fuzzel
        grim
        hyprpicker
        tesseract
        pavucontrol
        playerctl
        rofi-wayland
        swappy
        swaylock-effects
        swayidle
        slurp
        swww
        wayshot
        wlsunset
        wl-clipboard
        wf-recorder
        wayvnc
        jq

        # FILES
        cifs-utils # smb
        nfs-utils # nfs

        # NETWORKING
        ethtool

        # GAMES
        prismlauncher

        # MISC
        # android-file-transfer
        # appimage-run
        # texliveFull

        # Office-tools
        libreoffice

        php

        # (writeShellScriptBin "hello-bro" ''
        #   echo "Hello, ${config.home.username}!"
        # '')

        # 3D PRINTING
        freecad
        openscad
        solvespace
        blender
        prusa-slicer
        orca-slicer
      ]
      ++ (if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then [ unstable.lunar-client ] else [ ]);
  };
}
