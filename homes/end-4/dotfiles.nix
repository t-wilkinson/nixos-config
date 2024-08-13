{ config, impurity, inputs, pkgs, ... }: {
  xdg.configFile = let link = impurity.link; in {
    "ags".source = link ./.config/ags;
    "anyrun".source = link ./.config/anyrun;
    "fish".source = link ./.config/fish;
    "fontconfig".source = link ./.config/fontconfig;
    "foot".source = link ./.config/foot;
    "fuzzel".source = link ./.config/fuzzel;
    "hypr".source = link ./.config/hypr;
    "mpv".source = link ./.config/mpv;
    "qt5ct".source = link ./.config/qt5ct;
    "wlogout".source = link ./.config/wlogout;
    "zshrc.d".source = link ./.config/zshrc.d;
    "chrome-flags.conf".source = link ./.config/chrome-flags.conf;
    "code-flags.conf".source = link ./.config/code-flags.conf;
    "starship.toml".source = link ./.config/starship.toml;
    "thorium-flags.conf".source = link ./.config/thorium-flags.conf;
  };
}

