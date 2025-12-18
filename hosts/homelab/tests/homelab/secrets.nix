# ============================================================================
# secrets.nix - Secret management with agenix
# ============================================================================
{ config, pkgs, ... }:

{
  age.secrets = {
    wireguard-private-key = {
      file = ./secrets/wireguard-private-key.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };

    wifi-password = {
      file = ./secrets/wifi-password.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };

    nextcloud-admin-password = {
      file = ./secrets/nextcloud-admin-password.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };

    vaultwarden-admin-token = {
      file = ./secrets/vaultwarden-admin-token.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };

  # WiFi configuration using secret
  systemd.services.setup-wifi = {
    description = "Setup WiFi connection";
    wantedBy = [ "multi-user.target" ];
    after = [ "NetworkManager.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "setup-wifi" ''
        #!/bin/sh
        WIFI_PASSWORD=$(cat ${config.age.secrets.wifi-password.path})
        ${pkgs.networkmanager}/bin/nmcli device wifi connect "YOUR_SSID" password "$WIFI_PASSWORD" || true
      '';
    };
  };
}
