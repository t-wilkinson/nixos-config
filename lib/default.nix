{ self, ... }:
{
  mkConfigLinks =
    impurity:
    builtins.foldl' (
      acc: conf:
      acc
      // {
        ".config/${conf}".source = impurity.link "${self}/config/${conf}";
      }
    ) { };
}
