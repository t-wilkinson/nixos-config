{ username, ... }:
{
  imports = [
    ../homelab/inventory.nix
    ../../modules/homelab
  ];

  # Which services run here is decided by `host` in ../homelab/inventory.nix
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
