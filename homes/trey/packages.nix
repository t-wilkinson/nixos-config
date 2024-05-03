{ pkgs, ... }:
{

  home = {
    packages = with pkgs; with nodePackages_latest; with gnome; with libsForQt5; [
      i3 # gaming
      sway

      # gui
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

      # tools
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

      vscode
      lf
      tmux
      zellij
      foot
      kitty

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

      # langs
      nodejs
      gjs
      bun
      cargo
      go
      gcc
      typescript
      eslint
      # very important stuff
      # uwuify

      # minecraft

      # node
      nodePackages_latest.neovim
      # vimPlugins.nvim-treesitter.withPlugins
      # neovimUtils.makeNeovim

      # virtualisation
      # kvm
      # virt-manager
      # virt-viewer
      # spice
      # spice-gtk
      # spice-protocol
      # win-virtio
      # win-spice
      ];
  };
}
