{ pkgs, options, config, ... }:
let
  openvpnConfigs = pkgs.fetchzip {
    stripRoot = false;
    url = "https://www.privateinternetaccess.com/openvpn/openvpn.zip";
    hash = "sha256-ZA8RS6eIjMVQfBt+9hYyhaq8LByy5oJaO9Ed+x8KtW8=";
  };
  readConfig = file: builtins.readFile "${openvpnConfigs}/${file}";
in
{
  age.identityPaths = [ "${config.users.users.trey.home}/.ssh/id_rsa" ];
  age.secrets.vpn-config.file = ../secrets/vpn-config.age;
  age.secrets.vpn-pia-credentials.file = ../secrets/vpn-pia-credentials.age;

  services.openvpn.servers = {
    pia = {
      autoStart = false;
      config = ''
        ${readConfig config.age.secrets.vpn-config.path}
        auth-user-pass ${config.age.secrets.vpn-pia-credentials.path} 
      '';
    };
  };

  systemd.services."openvpn-pia" = {
    serviceConfig = {
      SupplementaryGroups = [ config.users.groups.keys.name ];
      ReadWritePaths = [ "/run" ];
    };
  };
}
