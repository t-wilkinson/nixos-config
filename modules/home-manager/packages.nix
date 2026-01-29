{ pkgs, unstable, ... }:
with pkgs;
[

  # TERMINAL EMULATORS
  # tmux
  alacritty
  kitty

  # GAMES
  # minecraft
  # unstable.lunar-client
  # steam

  # DESIGN
  # blender
  # figma-linux
  # gimp
  # inkscape
  # kolourpaint
  # pinta
  # krinta

  # GUI
  # vlc
  # vscode
  # slack
  # jetbrains-mono
  # jetbrains.phpstorm
  # github-desktop
  # reaper

  # TOOLS
  # pandoc
  # acpi
  age
  ssh-to-age
  aspell
  aspellDicts.en
  bat
  btop # pretty top
  clac
  colordiff
  difftastic # syntastic-aware diff
  # du-dust # du in rust
  eza # ls alternative
  feh
  ffmpeg
  # go-mtpfs
  # gojq # go implementation of jq
  htop
  hunspell
  imagemagick
  # inxi
  # jq
  lf # terminal file browser
  file # for lf
  sops
  starship
  # transmission_4 # bittorrent
  tree-sitter
  # ventoy # create bootable usb drives
  zoxide
  # zsh-powerlevel10k

  # MEDIA-RELATED PACKAGES
  # emacs-all-the-icons-fonts
  # pngquant # lossy png compressor
  dejavu_fonts
  glow # render markdown in terminal
  # jpegoptim # jpeg optimizer

  # ENCRYPTION AND SECURITY TOOLS
  # _1password-cli
  # age
  # age-plugin-yubikey
  gnupg
  pass
  # unstable.nodePackages."@bitwarden/cli"

  # SOURCE CODE MANAGEMENT, GIT, GITHUB TOOLS
  # gh
  # act # run github actions locally
  # git-filter-repo

  # PACKAGE MANAGEMENT/NIX
  # nh
  # nix-output-monitor
  # nvd

  # NETWORK
  tcpdump
  syncthing
]
