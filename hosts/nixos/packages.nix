{ pkgs, unstable, ... }:
{
  environment.systemPackages = with pkgs; [
    curl
    zsh
    fish
    git
    gh
    wget
    nixpkgs-fmt
    nixfmt-classic
    vim
    unstable.neovim
    gnumake
    gtk3
    efibootmgr
    # inputs.agenix.packages."${config.system}".default
    # inputs.agenix.packages."x86_64-linux".default

    iproute2

    # need the following for file uploads to work
    dbus
    nss
    gnutls
    libglvnd
  ];
}
