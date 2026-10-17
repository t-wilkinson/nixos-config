{ username, ... }:
{
  imports = [
    ../inventory.nix
    ../../modules/homelab
  ];

  # Which services run here is decided by `host` in ../inventory.nix
  homelab.thisNode = "pc";

  users.users.${username} = {
    extraGroups = [
      "serverdata"
      "personaldata"
    ];
  };

  security.pki.certificateFiles = [
    ../homelab/homelab-root.crt
  ];
}
