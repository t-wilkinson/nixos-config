{ ... }:
{
  nix.settings = {
    experimental-features = "nix-command flakes";
    substituters = [
      "https://nix-community.cachix.org"
      "https://cache.nixos.org/"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      #cudaSupport = true;
      #cudaCapabilities = ["8.0"];
      allowBroken = true;
      allowInsecure = false;
      # Not here: allowUnsupportedSystem makes meta.available lie. nixpkgs' CUDA packages add
      # cuda_compat (Jetson/aarch64 only) whenever it claims to be available, so on the PC every
      # CUDA package pulled in a cuda_compat with no x86_64 source and the build failed.
      # macOS keeps it (hosts/macos/default.nix).
      # allowUnsupportedSystem = true;
    };
  };
}
