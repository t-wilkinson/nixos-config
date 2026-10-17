# modules/homelab/fail2ban.nix
# fail2ban on the gateway (the only node reachable from the internet, through the tunnel).
# The sshd jail is on by default; services add their own jails (see vaultwarden.nix).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  homelab = config.homelab;
  nodes = homelab.nodes;
in
{
  config = lib.mkIf homelab.isGateway {
    # Nextcloud
    environment.etc."fail2ban/filter.d/nextcloud.conf".text = pkgs.lib.mkDefault (
      pkgs.lib.mkAfter ''
        [Definition]
        _groupsre = (?:(?:,?\s*"\w+":(?:"[^"]+"|\w+))*)
        failregex = ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Login failed:
                    ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Trusted domain error.
        datepattern = ,?\s*"time"\s*:\s*"%%Y-%%m-%%d[T ]%%H:%%M:%%S(%%z)?"
      ''
    );

    services.fail2ban = {
      enable = true;
      bantime = "24h";

      ignoreIP = [
        nodes.pc.ipv4
      ];

      jails = {
        # Already enabled for SSHD
        # sshd = ''
        #   enabled = true;
        #   maxretry = 3;
        # '';

        #     # Nextcloud
        #     # Converted to string to avoid "backend option does not exist" error
        #     nextcloud = ''
        #       enabled = true
        #       backend = auto
        #       port = 80,443
        #       protocol = tcp
        #       filter = nextcloud
        #       maxretry = 3
        #       bantime = 86400
        #       findtime = 43200
        #     '';
        #     # logpath = /var/lib/nextcloud/data/nextcloud.log
      };
    };
  };
}
