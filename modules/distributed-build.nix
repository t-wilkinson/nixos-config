{ pkgs, ...}:
{
  nix.distributedBuilds = true;
  nix.settings.builders-use-substitutes = true;

  nix.buildMachines = [
    {
      hostName = "pc.treywilkinson.com";
      sshUser = "trey";
      sshKey = "/Users/trey/.ssh/id_ed25519";
      system = pkgs.stdenv.hostPlatform.system;
      supportedFeatures = [ "nixos-test" "big-parallel" "kvm" ];
    }
  ];
}
