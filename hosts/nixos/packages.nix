{ pkgs, unstable, ... }:
{
  environment.systemPackages = with pkgs; [
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
  ];
}
