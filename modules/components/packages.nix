{ pkgs, unstable, ... }:
{
  environment.systemPackages =
    with pkgs;
    [
      # TERMINAL TOOLS
      zellij
      unstable.neovim

      # SHELLS
      fish
      zsh
      nushell

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

    ]
    ++ (
      if pkgs.stdenv.isLinux then
        [
          # inputs.agenix.packages."${config.system}".default
          # inputs.agenix.packages."x86_64-linux".default
          nix-ld
          gtk3
          efibootmgr
          iproute2
          psmisc # tools that use /proc
          usbutils
          stdenv.cc.cc.lib

          # need the following for file uploads to work
          dbus
          nss
          gnutls
          libglvnd
        ]
      else if pkgs.stdenv.isDarwin then
        [
          # darwin.iproute2mac
          # agenix.packages."${pkgs.system}".default
        ]
      else
        [ ]
    );
}
