{ username, ... }:
{
  imports = [
    ../../modules/homelab
  ];

  homelab = {
    enableServices = [
      # "mc-server"
    ];
  };

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
