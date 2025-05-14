{ pkgs, unstable, ... }:
{
  environment.systemPackages = with pkgs; [
    zsh
    fish
    nixpkgs-fmt
    nixfmt-classic
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

    pinentry
  ];
}
