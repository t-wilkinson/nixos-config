# modules/homelab/module.nix
{ lib, config, ... }:
with lib;
let
  hlcfg = config.homelab; # homelab config
  capitalizeFirst =
    s:
    if builtins.stringLength s == 0 then
      ""
    else
      (lib.toUpper (builtins.substring 0 1 s)) + (builtins.substring 1 (builtins.stringLength s - 1) s);

  # IPv4 arithmetic for the link's broadcast address (Wake-on-LAN target)
  ipToInt = ip: foldl' (acc: o: acc * 256 + toInt o) 0 (splitString "." ip);
  intToIp =
    n:
    concatMapStringsSep "." toString [
      (n / 16777216)
      (mod (n / 65536) 256)
      (mod (n / 256) 256)
      (mod n 256)
    ];
  blockSize = prefix: foldl' (acc: _: acc * 2) 1 (range 1 (32 - prefix));
in
{
  options.homelab = {
    lib = mkOption {
      type = types.attrs;
      default = { };
      description = "Library of helper functions for homelab";
    };
    username = mkOption {
      type = types.str;
    };
    adminEmail = mkOption {
      type = types.str;
      description = "The admin's email: the Authelia user's email, which Beszel matches to log in.";
    };
    adminKeys = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "SSH public keys allowed to log in as the admin user (and root, for deploys) on homelab nodes and bootstrap images.";
    };
    thisNode = mkOption {
      type = types.str;
      example = "pi";
      description = "Which entry of homelab.nodes this machine is. Services run where host == thisNode.";
    };
    groups = mkOption {
      type = types.attrsOf types.int;
      default = { };
      description = "group name -> gid. Helps with permissions across containers.";
      example = {
        personaldata = 987;
      };
    };
    # Disks, data directories and NFS shares: homelab.storage (./storage.nix)
    enableServices = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Services deployed somewhere in the homelab. Each runs on its own host.";
    };

    gateway = mkOption {
      type = types.str;
      example = "pi";
      description = ''
        Node that fronts the homelab: Caddy (both names for every exposed service), Blocky
        (LAN DNS), the Cloudflare tunnel, the Tailscale subnet router and the NFS exports.
      '';
    };
    isGateway = mkOption {
      type = types.bool;
      readOnly = true;
      default = hlcfg.thisNode == hlcfg.gateway;
      description = "True on the gateway node. Gateway modules (caddy.nix, blocky.nix, ...) gate on this.";
    };

    containerStateVersion = mkOption {
      type = types.str;
      default = config.system.stateVersion;
    };

    nodes = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, config, ... }:
          {
            options = {
              name = mkOption {
                type = types.str;
                default = capitalizeFirst name;
                description = "Pretty name (dashboard buttons).";
              };
              hostname = mkOption {
                type = types.str;
                default = name;
                description = "Hostname for system";
              };
              system = mkOption {
                type = types.nullOr types.str;
                default = null;
                example = "aarch64-linux";
                description = "Nix system double; used for deploys and bootstrap images.";
              };
              mac = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "MAC address of lanInterface (Wake-on-LAN target).";
              };
              lanInterface = mkOption {
                type = types.nullOr types.str;
                default = null;
                example = "enp4s0";
                description = "Interface on the homelab link (ipv4 lives here).";
              };
              wanInterface = mkOption {
                type = types.nullOr types.str;
                default = null;
                example = "wlan0";
                description = "Uplink to the internet (the gateway's NAT and Wi-Fi watchdog use it).";
              };
              wakeOnLan = mkOption {
                type = types.bool;
                default = false;
                description = "The node sleeps and can be woken with a magic packet (needs mac and lanInterface).";
              };
              sshHost = mkOption {
                type = types.nullOr types.str;
                default = config.ipv4;
                description = "Address deploy-rs and admins use to reach the node over SSH.";
              };
              ipv4 = mkOption {
                type = types.nullOr types.str;
                default = null;
                example = "192.168.1.10";
                description = "Address on the homelab link. Null for devices that aren't on it (e.g. a laptop).";
              };
              cidr = mkOption {
                type = types.nullOr types.str;
                default =
                  if config.ipv4 == null then null else "${config.ipv4}/${toString hlcfg.network.prefixLength}";
              };
              syncthingId = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Syncthing device ID.";
              };
              backupKey = mkOption {
                type = types.nullOr types.str;
                default = null;
                example = "ssh-ed25519 AAAA... backup@pc";
                description = ''
                  Public half of the SSH key this node's root uses for backup copies to and from
                  other nodes (./borg-mirror.nix). Other nodes only accept it for
                  those copies (forced commands), never for a shell.
                '';
              };
              backupKeyFile = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Private half of backupKey on this node (readable by root).";
              };
            };
          }
        )
      );
      description = "Set of nodes available across the homelab.";
    };

    network = {
      cidr = mkOption {
        type = types.str;
        example = "10.1.0.0/30";
      };
      baseAddress = mkOption {
        type = types.str;
        readOnly = true;
        default = builtins.head (lib.splitString "/" config.homelab.network.cidr);
      };
      prefixLength = mkOption {
        type = types.ints.between 0 32;
        readOnly = true;
        default = lib.toInt (lib.last (lib.splitString "/" config.homelab.network.cidr));
      };
      broadcast = mkOption {
        type = types.str;
        readOnly = true;
        default =
          let
            size = blockSize hlcfg.network.prefixLength;
          in
          intToIp ((ipToInt hlcfg.network.baseAddress / size) * size + size - 1);
        description = "Broadcast address of the homelab link (10.1.0.3 for 10.1.0.0/30).";
      };

      # homelabNetwork = mkOption {
      #   type = types.str;
      # };
      domain = mkOption {
        type = types.str;
        default = "home.lab";
      };
      publicDomain = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Base public domain (e.g., example.com)";
      };
      cloudflareTunnelId = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "UUID of the cloudflared tunnel (<id>.cfargotunnel.com).";
      };
      privateRanges = mkOption {
        type = types.listOf types.str;
        # Loopback is deliberately NOT included (unlike Caddy's `private_ranges` shorthand):
        # cloudflared connects from 127.0.0.1, so tunnel traffic can never count as LAN, even if
        # a request somehow arrived without Cf-Connecting-Ip. LAN clients and the Pi itself
        # reach Caddy via 10.x / 192.168.x / the tailnet.
        default = [
          "10.0.0.0/8"
          "172.16.0.0/12"
          "192.168.0.0/16"
          "fd00::/8"
          "100.64.0.0/10" # tailnet (IPv4)
          "fd7a:115c:a1e0::/48" # tailnet (IPv6)
        ];
        description = "Caddy client_ip ranges treated as LAN/tailnet.";
      };
      containerNetwork = mkOption {
        type = types.str;
        default = "192.168.100";
      };
      hostContainerIP = mkOption {
        type = types.str;
        default = "${hlcfg.network.containerNetwork}.1";
      };
    };

    services = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, config, ... }:
          {
            options = {
              enable = mkOption {
                type = types.bool;
                default = false;
                description = "Whether the service is deployed somewhere in the homelab (see host).";
              };

              host = mkOption {
                type = types.nullOr types.str;
                default = null;
                example = "pc";
                description = "Name of the node in homelab.nodes that runs this service.";
              };
              runsHere = mkOption {
                type = types.bool;
                readOnly = true;
                default = config.enable && config.host == hlcfg.thisNode;
                description = "True when the service is enabled and this machine is its host. Service modules gate on this.";
              };

              data = mkOption {
                type = types.submodule {
                  freeformType = types.attrsOf types.anything;
                  options = {
                    # global options
                  };
                };
                default = { };
                description = "Additional information to be used by service";
              };

              port = mkOption {
                type = types.nullOr types.int;
                default = null;
              };
              extraPorts = mkOption {
                type = types.listOf types.int;
                default = [ ];
                description = "Additional ports to forward in container";
              };

              id = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "Marks service as a container with private network. The container's ip address becomes containerNetwork.id. It will automatically forward the service's declared port.";
              };
              localIP = mkOption {
                readOnly = true;
                default =
                  if config.host != null && config.host != hlcfg.thisNode then
                    # Runs on another node: reach it over the homelab link
                    hlcfg.nodes.${config.host}.ipv4
                  else if config.id != null then
                    "${hlcfg.network.containerNetwork}.${toString config.id}"
                  else
                    "127.0.0.1";
                type = types.str;
                description = "The calculated internal IP address, as seen from this machine.";
              };
              localEndpoint = mkOption {
                readOnly = true;
                default = "${config.localIP}:${toString config.port}";
                type = types.str;
                description = "The calculated endpoint = ip_address:port";
              };
              # uri = mkOption {
              #   readOnly = true;
              #   default = "http://${config.localEndpoint}";
              #   type = types.str;
              # };

              expose = mkOption {
                type = types.bool;
                default = true;
                description = "Determines whether to create (sub)domain and expose service through cloudflare/caddy.";
              };

              subdomain = mkOption {
                type = types.nullOr types.str;
                default = if config.expose then name else null;
              };
              domain = mkOption {
                type = types.nullOr types.str;
                default = if config.expose then "${config.subdomain}.${hlcfg.network.domain}" else null;
              };

              isPublic = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Route publicDomain through the Cloudflare tunnel. Every exposed service answers on
                  domain and publicDomain from the LAN/tailnet; only public ones are reachable from the internet.
                '';
              };
              publicSubdomain = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
              publicDomain = mkOption {
                type = types.nullOr types.str;
                default =
                  if hlcfg.network.publicDomain != null && config.publicSubdomain != null then
                    # public subdomain . public domain
                    "${config.publicSubdomain}.${hlcfg.network.publicDomain}"
                  else if hlcfg.network.publicDomain != null && config.subdomain != null then
                    # subdomain . public domain (LAN-only unless isPublic)
                    "${config.subdomain}.${hlcfg.network.publicDomain}"
                  else
                    null;
              };

              auth = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Put the service behind the homelab login (Authelia, homelab.services.auth): Caddy
                  asks Authelia before proxying, so one password covers every such service.
                '';
              };
              authBypass = mkOption {
                type = types.listOf types.str;
                default = [ ];
                example = [ "/api/*" ];
                description = "Caddy path patterns that skip the login (e.g. an API that has its own token).";
              };

              extraConfig = mkOption {
                type = types.lines;
                default = "";
                description = "Extra Caddyfile lines for this service's site block (placed before the default handle).";
              };
              proxyConfig = mkOption {
                type = types.lines;
                default = "";
                example = "header_up Host {upstream_hostport}";
                description = "Extra lines inside this service's reverse_proxy block.";
              };

              name = mkOption {
                type = types.str;
                default = capitalizeFirst name;
                description = "Pretty name for Dashboard";
              };
              description = mkOption {
                type = types.str;
                default = "";
              };
              paths = mkOption {
                type = types.attrsOf types.str;
                description = "Maps of paths to endpoints";
                example = {
                  "/notes" = "127.0.0.1:8090";
                };
                default = { };
              };

              dashboard = {
                category = mkOption {
                  type = types.nullOr types.str;
                  default = if config.expose then "Applications" else null;
                  description = "Homepage group the service's tile goes in; null = no tile.";
                };
                icon = mkOption {
                  type = types.str;
                  default = "";
                  example = "mdi-bell-ring";
                };
                extra = mkOption {
                  type = types.attrs;
                  default = { };
                  example = {
                    ping = "https://budget.home.lab";
                  };
                  description = "Extra homepage tile settings (widget, ping, ...).";
                };
              };

              units = mkOption {
                type = types.listOf types.str;
                default = [ ];
                example = [ "vaultwarden.service" ];
                description = "systemd units that make up the service; homelab-status checks them on its host.";
              };
              monitor = mkOption {
                type = types.bool;
                default = true;
                description = "Include the service in homelab-status checks (false for things run by hand).";
              };
            };
          }
        )
      );
    };
  };

  config = {
    assertions = [
      {
        assertion = hasAttr hlcfg.thisNode hlcfg.nodes;
        message = "homelab.thisNode = \"${hlcfg.thisNode}\" is not in homelab.nodes.";
      }
    ]
    ++ mapAttrsToList (name: s: {
      assertion = !s.enable || (s.host != null && hasAttr s.host hlcfg.nodes);
      message = "homelab.services.${name} is enabled but its host (${toString s.host}) is not in homelab.nodes.";
    }) hlcfg.services
    ++ mapAttrsToList (name: s: {
      assertion = !(s.enable && s.auth) || (hlcfg.services ? auth && hlcfg.services.auth.enable);
      message = "homelab.services.${name}.auth = true needs the auth service (Authelia) enabled.";
    }) hlcfg.services;

    users.groups = mapAttrs (name: gid: { inherit gid; }) hlcfg.groups;
    containers =
      let
        containerServices = filterAttrs (n: v: v.id != null && v.runsHere) hlcfg.services;
      in
      mapAttrs (n: v: {
        config =
          { config, ... }:
          {
            system.stateVersion = lib.mkDefault hlcfg.containerStateVersion;
            users.groups = mapAttrs (name: gid: { inherit gid; }) hlcfg.groups;
            networking.firewall.allowedTCPPorts = [ v.port ] ++ v.extraPorts;
          };

        privateNetwork = true;
        hostAddress = hlcfg.network.hostContainerIP;
        localAddress = v.localIP;
        forwardPorts = lib.mkDefault (
          map (p: {
            protocol = "tcp";
            hostPort = p;
            containerPort = p;
          }) ([ v.port ] ++ v.extraPorts)
        );
      }) containerServices;

    homelab.services = lib.genAttrs hlcfg.enableServices (name: {
      enable = true;
    });
    homelab.lib = {
      # Caddy client_ip matcher arguments for "LAN or tailnet" (see network.privateRanges)
      caddyPrivateRanges = concatStringsSep " " (hlcfg.network.privateRanges ++ [ hlcfg.network.cidr ]);

      mkRoMount = path: {
        "${path}" = {
          hostPath = path;
          isReadOnly = true;
        };
      };

      mkSecretMounts = secretsList: foldl' (acc: s: acc // (hlcfg.lib.mkRoMount s.path)) { } secretsList;
    };
  };
}
