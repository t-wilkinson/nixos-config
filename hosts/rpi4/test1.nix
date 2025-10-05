# nix build .#image.rpi4
{ pkgs, ... }:
{
  config = {
    time.timeZone = "Europe/Rome";
    i18n.defaultLocale = "it_IT.UTF-8";
    sdImage.compressImage = false;
    console.keyMap = "it";

    users.users.root.initialHashedPassword = "$y$j9T$/29noYRT4W/22Hy4lW7B71$MNtGBgjk01Zo3LtKgFRQtwaXdv6I15oiSgGGCMkt9s2"; # =test use mkpasswd to generate
    system = {
      stateVersion = "23.05";
    };
    networking = {
      wireless.enable = false;
      useDHCP = false;
    };
    environment.systemPackages = with pkgs; [
      git
      gnupg
    ];
  };
}
