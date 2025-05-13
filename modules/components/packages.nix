{ pkgs, unstable, ... }:
{
  environment.systemPackages = with pkgs; [
    # TERMINAL EMULATORS & MULTIPLEXERS
    # foot
    # tmux
    # alacritty
    kitty
    zellij
    unstable.neovim

    # CORE CLI TOOLS
    fzf
    ripgrep
    tree
    wget
    fd
    lsof
    curl

    # SYSTEM TOOLS & CORE UTILITIES
    cmake
    coreutils
    bash-completion
    killall
    zip
    unzip
    unrar
    # psmisc # tools that use /proc
    openssh
    wireguard-tools
    # usbutils
    # libnotify
    # stdenv.cc.cc.lib
    icu # unicode and globalization support library

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
    dnsmasq

    # PACKAGE MANAGEMENT/NIX
    nh
    # nix-ld
    nix-output-monitor
    nvd

    # ENCRYPTION AND SECURITY TOOLS
    _1password-cli
    age
    age-plugin-yubikey
    gnupg
    pass
    # pinentry # library for GUI password entry

    # GENERAL PACKAGES FOR DEVELOPMENT AND SYSTEM MANAGEMENT
    act
    bat
    btop
    difftastic
    du-dust
    # git-filter-repo
    # neofetch
    # pandoc
    uv

    # MEDIA-RELATED PACKAGES
    imagemagick
    # emacs-all-the-icons-fonts
    pngquant
    ffmpeg
    dejavu_fonts
    glow
    jpegoptim

    # SOURCE CODE MANAGEMENT, GIT, GITHUB TOOLS
    gh
    git

    # Text and terminal utilities
    htop
    aspell
    aspellDicts.en
    hunspell
    jq
    # slack
    # jetbrains-mono
    # jetbrains.phpstorm
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
  ];
}
