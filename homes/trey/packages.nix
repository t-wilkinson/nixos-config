{ pkgs, ... }:
{

  home = {
    packages = with pkgs; with nodePackages_latest; with gnome; with libsForQt5; [
      i3 # GAMING
      sway

      # TERMINAL EMULATORS
      tmux
      zellij
      foot
      kitty
      tmux
      neovide

      # LANGS
      R
      bun
      eslint
      gcc
      gjs
      go
      nodejs
      php
      typescript
      rustup
      elixir
      # jdk # has compatibility issues
      dart

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
      sqlite
      ollama
      maven

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
      # reaper # conflicts with `jdk`
      (google-chrome.override {
       commandLineArgs = [
        "--enable-features=UseOzonePlatform"
        "--ozone-platform=wayland"
       ];
      })
      # kdePackages.dolphin
      pinta

      # DESIGN
      figma-linux
      inkscape
      gimp
      blender
      kolourpaint

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

      # VIRTUALISATION
      virt-manager
      virt-viewer
      spice
      spice-gtk
      spice-protocol
      win-virtio
      win-spice
      # lxc
      # lxd-lts
      distrobuilder
      incus

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
