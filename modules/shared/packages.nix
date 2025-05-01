{ pkgs, ... }:

with pkgs; [
  # TERMINAL EMULATORS & MULTIPLEXERS
  # foot
  kitty
  # tmux
  zellij
  # alacritty

  # CORE CLI TOOLS
  fzf
  ripgrep
  tree
  wget
  fd
  lsof

  # SYSTEM TOOLS & CORE UTILITIES
  coreutils
  bash-completion
  killall
  zip
  unzip
  unrar
  psmisc # tools that use /proc
  openssh
  usbutils
  libnotify

  # DEVELOPMENT/BUILD ESSENTIALS
  gcc
  sqlite
  openssl
  libfido2

  # NETWORKING TOOLS
  dig
  iftop
  nmap
  socat

  # PACKAGE MANAGEMENT/NIX
  nh
  nix-ld
  nix-output-monitor
  nvd

  # ENCRYPTION AND SECURITY TOOLS
  _1password
  age
  age-plugin-yubikey
  gnupg
  pass
  pinentry # library for GUI password entry

  # GENERAL PACKAGES FOR DEVELOPMENT AND SYSTEM MANAGEMENT
  act
  bat
  btop
  difftastic
  du-dust
  git-filter-repo
  # neofetch
  # pandoc
  uv

  # MEDIA-RELATED PACKAGES
  emacs-all-the-icons-fonts
  imagemagick
  dejavu_fonts
  ffmpeg
  font-awesome
  glow
  hack-font
  jpegoptim
  meslo-lgs-nf
  noto-fonts
  noto-fonts-emoji
  pngquant

  # SOURCE CODE MANAGEMENT, GIT, GITHUB TOOLS
  gh

  # Text and terminal utilities
  htop
  aspell
  aspellDicts.en
  hunspell
  # jetbrains-mono
  # jetbrains.phpstorm
  jq
  slack
  # zsh-powerlevel10k

  # TOOLS
  # acpi
  # bat
  # clac
  # eza
  # feh
  # glib
  # gojq
  # htop
  # inxi
  # jq
  # lf
  # showmethekey
  # starship
  # transmission_4
  # ventoy
  # ydotool
  # zoxide
  # go-mtpfs
  # colordiff
]
