{
  self,
  inputs,
  pkgs,
  ...
}:
let
  agsStartScript = pkgs.writeShellScriptBin "run_ags" ''
    #!/usr/bin/env bash

    AGS_VIRTUAL_ENV=$HOME/.local/state/ags/.venv

    if [ ! -d "$AGS_VIRTUAL_ENV" ]; then
      UV_NO_MODIFY_PATH=1
      mkdir -p "$AGS_VIRTUAL_ENV"
      # we need python 3.12 https://github.com/python-pillow/Pillow/issues/8089
      uv venv --prompt .venv "$AGS_VIRTUAL_ENV" -p 3.12
      source "$AGS_VIRTUAL_ENV/bin/activate"
      uv pip install -r ${self}/config/ags/requirements.txt
      deactivate # We don't need the virtual environment anymore
    fi

    ags -c ${self}/config/ags/config.js
  '';
in
{
  imports = [
    inputs.ags.homeManagerModules.default
  ];

  home.packages = with pkgs; [
    agsStartScript
    ollama
    pywal
    sassc
    ddcutil
    sass
    gjs
  ];

  programs.ags = {
    enable = true;
    configDir = null; # if ags dir is managed by home-manager, it'll end up being read-only. not too cool.
    # configDir = ./.config/ags;

    extraPackages = with pkgs; [
      gtksourceview
      gtksourceview4
      ollama
      python311Packages.material-color-utilities
      python311Packages.pywayland
      pywal
      sassc
      webkitgtk
      webp-pixbuf-loader
      ydotool
    ];
  };
}
