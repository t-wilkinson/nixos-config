{ pkgs, options, config, ... }:
let
  openvpnConfigs = pkgs.fetchzip {
    stripRoot = false;
    url = "https://www.privateinternetaccess.com/openvpn/openvpn.zip";
    hash = "sha256-ZA8RS6eIjMVQfBt+9hYyhaq8LByy5oJaO9Ed+x8KtW8=";
  };

  vpnSetupScript = pkgs.writeShellScript "vpn-setup" ''
    #!/bin/sh
    VPN_FILE=$(cat ${config.age.secrets.vpn-config.path})
    if [ -f "${openvpnConfigs}/$VPN_FILE" ]; then
      cp "${openvpnConfigs}/$VPN_FILE" /run/openvpn-config
      echo "auth-user-pass ${config.age.secrets.vpn-pia-credentials.path}" >> /run/openvpn-config
    else
      echo "Error: VPN configuration file $VPN_FILE not found" >&2
      exit 1
    fi
  '';
in
{
  age.identityPaths = [ "${config.users.users.trey.home}/.ssh/id_rsa" ];
  age.secrets.vpn-config.file = ../secrets/vpn-config.age;
  age.secrets.vpn-pia-credentials.file = ../secrets/vpn-pia-credentials.age;

  services.openvpn.servers = {
    pia = {
      autoStart = false;
      config = "config /run/openvpn-config";
    };
  };

  systemd.services."openvpn-pia" = {
    serviceConfig = {
      ExecStartPre = [
        "${vpnSetupScript}"
      ];
      SupplementaryGroups = [ config.users.groups.keys.name ];
      ReadWritePaths = [ "/run" ];
    };
  };
}
