{ config, pkgs, lib, zjstatus, ...}:

{
  nixpkgs.overlays = [
    (final: prev: {
      zjstatus = zjstatus.packages.${prev.system}.default;
    })
    # ../modules/lf.nix
  ];
}
