{ config, impurity, inputs, pkgs, ... }: {
  xdg.configFile = let link = impurity.link; in {
    "ags".source = link ./.config/ags;
    "anyrun".source = link ./.config/anyrun;
    "fish".source = link ./.config/fish;
    "foot".source = link ./.config/foot;
    "fuzzel".source = link ./.config/fuzzel;
    "hypr".source = link ./.config/hypr;
    "mpv".source = link ./.config/mpv;
    "thorium-flags.conf".source = link ./.config/thorium-flags.conf;
    "starship.toml".source = link ./.config/starship.toml;
    "zellij".source = link ./.config/zellij;
    "nvim".source = link ./.config/nvim;
  };
}

