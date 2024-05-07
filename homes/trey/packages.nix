{ pkgs, ... }:
{

  home = {
    packages = with pkgs; with nodePackages_latest; with gnome; with libsForQt5; [
      i3 # GAMING
      sway

      # GUI
      blueberry
      (mpv.override { scripts = [ mpvScripts.mpris ]; })
      d-spy
      dolphin
      figma-linux
      kolourpaint
      github-desktop
      gnome.nautilus
      icon-library
      dconf-editor
      qt5.qtimageformats
      vlc
      yad
      tor-browser-bundle-bin
      inkscape
      gimp
      zathura
      okular

      vscode
      tmux
      zellij
      foot
      kitty
      tmux
      neovide

      # TOOLS
      bat
      eza
      fd
      ripgrep
      fzf
      socat
      jq
      gojq
      acpi
      ffmpeg
      libnotify
      killall
      zip
      unzip
      glib
      starship
      showmethekey
      ydotool
      tree
      nvd
      nix-output-monitor
      nh
      zoxide
      feh
      lf

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

      # LANGS
      nodejs
      gjs
      bun
      cargo
      go
      gcc
      typescript
      eslint

      # GAMES
      minecraft
      prismlauncher
      steam

      # NODE
      nodePackages_latest.neovim
      # vimPlugins.nvim-treesitter.withPlugins
      # neovimUtils.makeNeovim

      # VIRTUALISATION
      virt-manager
      virt-viewer
      spice
      spice-gtk
      spice-protocol
      win-virtio
      win-spice
    ];
  };
}
