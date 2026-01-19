{
  self,
  inputs,
}:
with inputs;
let
  # homelab utilites
  mkHomelabApps =
    system: pkgs:
    let
      mkHomelabApp = scriptName: deps: {
        type = "app";
        program = "${(pkgs.writeScriptBin scriptName ''
          #!${pkgs.bash}/bin/bash
          export PATH="${pkgs.lib.makeBinPath deps}:$PATH"
          exec ${self}/apps/homelab/${scriptName} "$@"
        '')}/bin/${scriptName}";
      };
    in
    rec {
      "h-build-image" = mkHomelabApp "build-image" [
        pkgs.zstd
        pkgs.coreutils
        pkgs.nix
      ];
      "h-flash-image" = mkHomelabApp "flash-image" [
        pkgs.zstd
        pkgs.coreutils
        pkgs.util-linux
      ];
      "h-build-flash" = mkHomelabApp "build-flash" [
        pkgs.zstd
        pkgs.coreutils
        pkgs.util-linux
        pkgs.nix
      ];
      "h-remote-build" = mkHomelabApp "remote-build" [
        pkgs.openssh
        pkgs.nixos-rebuild
      ];
      "h" = h-remote-switch;
      "h-remote-switch" = mkHomelabApp "remote-switch" [
        pkgs.openssh
        pkgs.nixos-rebuild
      ];
    }
    // mkHomelabApps system pkgs;

  mkApp = pkgs: scriptName: system: {
    type = "app";
    program = "${(pkgs.writeScriptBin scriptName ''
      #!/usr/bin/env bash
      PATH=${pkgs.git}/bin:$PATH
      echo "Running ${scriptName} for ${system}"
      exec ${self}/apps/${system}/${scriptName}
    '')}/bin/${scriptName}";
  };

  mkLinuxApps =
    system:
    let
      pkgs = nixpkgs-nixos.legacyPackages.${system};
      app = scriptName: mkApp pkgs scriptName system;
    in
    {
      "apply" = app "apply";
      "b" = app "build-impure";
      "bs" = app "build-switch-impure";
      "build" = app "build";
      "build-impure" = app "build-impure";
      "build-switch" = app "build-switch";
      "build-switch-impure" = app "build-switch-impure";
      "copy-keys" = app "copy-keys";
      "create-keys" = app "create-keys";
      "check-keys" = app "check-keys";
      "install" = app "install";
      "install-with-secrets" = app "install-with-secrets";
    }
    // mkHomelabApps system pkgs;

  mkDarwinApps =
    system:
    let
      pkgs = nixpkgs-darwin.legacyPackages.${system};
      app = scriptName: mkApp pkgs scriptName system;
    in
    {
      "apply" = app "apply";
      "b" = app "build-impure";
      "bs" = app "build-switch-impure";
      "build" = app "build";
      "build-impure" = app "build-impure";
      "build-switch" = app "build-switch";
      "build-switch-impure" = app "build-switch-impure";
      "copy-keys" = app "copy-keys";
      "create-keys" = app "create-keys";
      "check-keys" = app "check-keys";
      "rollback" = app "rollback";
    };
in
{
  linux = mkLinuxApps;
  darwin = mkDarwinApps;
  homelab = mkHomelabApps;
}
