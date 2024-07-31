{ config, impurity, inputs, pkgs, ... }: {
  xdg.configFile = let link = impurity.link; in {
    "ags".source = link ./.config/ags;
    # "colors.conf".source = link ./.config/hypr/colors.conf;
    "fish".source = link ./.config/fish;
    "foot".source = link ./.config/foot;
    "fuzzel".source = link ./.config/fuzzel;
    "mpv".source = link ./.config/mpv;
    "thorium-flags.conf".source = link ./.config/thorium-flags.conf;
    "starship.toml".source = link ./.config/starship.toml;
    "zellij".source = link ./.config/zellij;
    "nvim".source = link ./.config/nvim;
  };
}

