{
  self,
  pkgs,
  inputs,
  ...
}:
inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
  inherit pkgs;
  settings = { };
}
