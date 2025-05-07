{ pkgs, ...}:
{
  environment.systemPackages = with pkgs; [
    font-awesome
    hack-font
    meslo-lgs-nf
    noto-fonts
    noto-fonts-emoji
  ];

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
  #   fontconfig.defaultFonts = {
  #     serif = [ "Noto Serif" "Source Han Serif" ];
  #     sansSerif = [ "Noto Sans" "Source Han Sans" ];
  #   };
  # };
}
