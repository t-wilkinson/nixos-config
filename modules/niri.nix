{
  inputs,
  lib,
  pkgs,
  self,
  ...
}:
let
  myNoctalia = self.packages.${pkgs.stdenv.hostPlatform.system}.myNoctalia;
in
inputs.wrapper-modules.wrappers.niri.wrap {
  inherit pkgs;
  settings = {
    spawn-at-startup = [
      (lib.getExe myNoctalia)
    ];
    input.keyboard = {
      xkb.layout = "us";
    };
    layout.gaps = 5;
    binds = {
      "Mod+S".spawn-sh = "${lib.getExe myNoctalia} ipc call launcher toggle";
      "Mod+Return".spawn-sh = lib.getExe pkgs.kitty;
      "Mod+Q".close-window = null;
    };
  };
}
