{ pkgs, unstable, ... }:
{
  environment.systemPackages = with pkgs; [
    # TERMINAL TOOLS
    zellij
    unstable.neovim

    # SHELLS
    fish
    zsh

    # CORE CLI TOOLS
    curl
    fd
    fzf
    git
    lsof
    ripgrep
    tree
    unrar
    unzip
    wget
    zip

    # SYSTEM TOOLS & CORE UTILITIES
    glib
    cmake
    gnumake
    coreutils
    bash-completion
    killall
    icu # unicode and globalization support library

    # DEVELOPMENT/BUILD ESSENTIALS
    gcc
    sqlite
    openssl
    libfido2

    # NETWORKING TOOLS
    dig
    dnsmasq
    iftop
    nmap
    openssh
    socat
    wireguard-tools
  ];
}
