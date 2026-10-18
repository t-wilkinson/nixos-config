{ self, ... }:
rec {
  # A symlink in the store that points at a path outside it (what Home Manager's
  # config.lib.file.mkOutOfStoreSymlink does). Home Manager links ~/.config/<x> to it, so
  # the file stays live: edits in the working copy apply without a rebuild, and evaluation
  # stays pure (no --impure, no IMPURITY_PATH).
  mkOutOfStoreSymlink =
    pkgs: path:
    let
      pathStr = toString path;
      # store names may not start with "." or contain odd characters
      name = builtins.replaceStrings [ "." ] [ "-" ] (baseNameOf pathStr);
    in
    pkgs.runCommandLocal "oos-${name}" { } "ln -s ${pkgs.lib.escapeShellArg pathStr} $out";

  # .config/<name> -> <configDir>/config/<name> in the working copy (configDir: flake.nix)
  mkConfigLinks =
    pkgs: configDir:
    builtins.foldl' (
      acc: conf:
      acc
      // {
        ".config/${conf}".source = mkOutOfStoreSymlink pkgs "${configDir}/config/${conf}";
      }
    ) { };
}
