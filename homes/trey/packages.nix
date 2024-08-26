{ pkgs, ... }:
{
  home = {
    packages = with pkgs; with nodePackages_latest; with gnome; with libsForQt5; [
      i3 # GAMING
      sway

      # TERMINAL EMULATORS
      foot
      kitty
      neovide
      tmux
      tmux
      zellij

      # GUI
      blueberry # bluetooth
      (mpv.override { scripts = [ mpvScripts.mpris ]; })
      d-spy
      dolphin
      github-desktop
      gnome.nautilus
      icon-library
      dconf-editor
      qt5.qtimageformats
      vlc
      yad
      tor-browser-bundle-bin
      zathura # document viewer
      okular # document viewer
      vscode
      # reaper # conflicts with `jdk`
      (google-chrome.override {
       commandLineArgs = [
        "--enable-features=UseOzonePlatform"
        "--ozone-platform=wayland"
       ];
      })
      # kdePackages.dolphin

      # DESIGN
      blender
      figma-linux
      gimp
      inkscape
      kolourpaint
      pinta

      # TOOLS
      acpi
      bat
      clac
      eza
      fd
      feh
      ffmpeg
      fzf
      glib
      gojq
      htop
      inxi
      jq
      killall
      lf
      libnotify
      lsof
      nh
      nix-ld
      nix-output-monitor
      nvd
      openssl
      psmisc
      ripgrep
      showmethekey
      socat
      starship
      transmission
      tree
      unzip
      usbutils
      ventoy
      ydotool
      zip
      zoxide
      go-mtpfs
      nmap
      dig
      colordiff

      # SECURITY
      pass
      gnupg
      pinentry

      # THEMING TOOLS
      gradience
      gnome-tweaks

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
      swww
      wayshot
      wlsunset
      wl-clipboard
      wf-recorder
      wayvnc

      # NODE
      nodePackages_latest.neovim
      # vimPlugins.nvim-treesitter.withPlugins
      # neovimUtils.makeNeovim

      # GAMES
      minecraft
      lunar-client
      prismlauncher
      steam

      # MISC
      android-file-transfer
      appimage-run
      texliveFull

      # (writeShellScriptBin "hello-bro" ''
      #   echo "Hello, ${config.home.username}!"
      # '')
    ];
  };
}
