{ self, impurity, ... }: {
  imports = [ impurity.nixosModules.impurity ];
  impurity.configRoot = self;
  impurity.enable = true;
}
