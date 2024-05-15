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
      github-desktop
      gnome.nautilus
      icon-library
      dconf-editor
      qt5.qtimageformats
      vlc
      yad
      tor-browser-bundle-bin
      zathura
      okular
      vscode
      reaper

      # DESIGN
      figma-linux
      inkscape
      gimp
      blender
      kolourpaint

      # TERMINAL EMULATORS
      tmux
      zellij
      foot
      kitty
      tmux
      neovide

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
      inxi
      jq
      killall
      lf
      libnotify
      nh
      nix-output-monitor
      nvd
      ripgrep
      showmethekey
      socat
      starship
      tree
      unzip
      ydotool
      zip
      zoxide

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
      R

      # DEVELOPMENT
      awscli2
      docker
      docker-compose
      kubernetes
      # k3s
      minikube
      terraform
      vsh # HashiCorp Vault Shell
      vault # HashiCorp Vault 
      azure-cli
      direnv

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

      # GAMES
      minecraft
      lunar-client
      prismlauncher
      steam

      # MISC
      appimage-run
      texliveFull

      # (writeShellScriptBin "hello-bro" ''
      #   echo "Hello, ${config.home.username}!"
    ];
# '')
  };
}
