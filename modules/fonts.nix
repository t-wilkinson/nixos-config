{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # fira-code
    font-awesome
    hack-font
    meslo-lgs-nf
    noto-fonts
    noto-fonts-emoji
    # liberation_ttf
  ];

  # # pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; });
  # fonts = {
  # fonts = {
  #   packages = with pkgs; [
  #     fira-code
  #     noto-fonts
  #     noto-fonts-cjk-sans
  #     noto-fonts-emoji
  #     font-awesome
  #     source-han-sans
  #     source-han-sans-japanese
  #     source-han-serif-japanese
  #   ];
  #   fontconfig = {
  #     enable = true;
  #     defaultFonts = {
  #       # sansSerif = [ "Inter" "Roboto" "Ubuntu" "DejaVu Sans" ];
  #       # serif     = [ "DejaVu Serif" ];
  #       # monospace = [ "Fira Code" ];
  #       # emoji     = [ "Noto Color Emoji" ];
  #     };
  #   };
  # };
}
