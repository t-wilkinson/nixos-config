#!/bin/bash

if [ -d /tmp/dots-hyprland ]; then
  cd /tmp/dots-hyprland
  git pull
else
  git clone --depth 1 https://github.com/end-4/dots-hyprland /tmp/dots-hyprland
fi

mkdir -p ~/dev/t-wilkinson/nixos-config/homes/end-4/.config
rsync -aP --delete /tmp/dots-hyprland/.config/ ~/dev/t-wilkinson/nixos-config/homes/end-4/.config
