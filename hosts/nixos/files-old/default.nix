{ pkgs, ... }:
{
  imports = [
    # ./ags.nix
    # ./sway.nix
    #./dconf.nix
    #./theme.nix
    # ./anyrun.nix
    # ./cachix.nix
    # ./browser.nix
    # ./dotfiles.nix
    #./hyprland.nix
    # ./mimelist.nix
    #./packages.nix
    # ./startship.nix

  ];

  home.packages = with pkgs; [
    # launcher
    starship
    anyrun
    sway
  ];
  programs = {
  };
}
