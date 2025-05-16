{ pkgs, ... }:
{

  home = {
    packages = with pkgs; [
      i3
      sway
      pinentry
      foot

      # VIRTUALIZATION
      k3s
      incus

      # GUI
      okular # pdf viewer
      # zathura # pdf viewer
      blueberry
      (mpv.override { scripts = [ mpvScripts.mpris ]; })
      d-spy
      dolphin
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
