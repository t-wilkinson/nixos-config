{ inputs, ... }:
let inherit (inputs) zjstatus;

in {
  # unstable-packages = final: prev: {
  #   unstable = import inputs.nixpkgs-unstable {
  #     system = final.system;
  #     config.allowUnfree = true;
  #     config.allowBroken = true;
  #   };
  # };

  additions = final: prev: {
    zjstatus = zjstatus.packages.${prev.system}.default;
  };

  # nixpkgs.overlays = [
  #   (final: prev: {
  #     zjstatus = zjstatus.packages.${prev.system}.default;
  #   })
  #   # ../modules/lf.nix
  # ];
}
