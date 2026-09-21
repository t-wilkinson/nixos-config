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
    groups = mkOption {
      type = types.attrsOf types.int;
      default = { };
      description = "group name -> gid. Helps with permissions across containers.";
      example = {
        personaldata = 987;
      };
    };
    drives = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        backup = "/mnt/backup";
      };
      description = "drive name -> path.";
    };
    enableServices = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };

    containerStateVersion = mkOption {
      type = types.str;
      default = config.system.stateVersion;
    };

    nodes = mkOption {
      type = types.attrsOf (
        types.submodule (
          { config, ... }:
          {
            options = {
              mac = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
              ipv4 = mkOption {
                type = types.str;
                example = "192.168.1.10";
              };
              cidr = mkOption {
                type = types.str;
                default = "${config.ipv4}/${toString hlcfg.network.prefixLength}";
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
              };

              reverseProxy = mkOption {
                type = types.nullOr types.str;
                default = null;
                example = "100.1.0.10";
                description = "Reverse proxy ip address";
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
                  if config.id != null then
                    "${hlcfg.network.containerNetwork}.${toString config.id}"
                  else if config.reverseProxy != null then
                    config.reverseProxy
                  else
                    "127.0.0.1";
                type = types.str;
                description = "The calculated internal IP address.";
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
              };
              publicSubdomain = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
              publicDomain = mkOption {
                type = types.nullOr types.str;
                default =
                  let
                    defaultDomain = "${config.subdomain}.${hlcfg.network.publicDomain}";
                    publicDomain = "${config.publicSubdomain}.${hlcfg.network.publicDomain}";
                  in
                  if hlcfg.network.publicDomain != null && config.publicSubdomain != null then
                    # public subdomain . public domain
                    "${config.publicSubdomain}.${hlcfg.network.publicDomain}"
                  else if hlcfg.network.publicDomain != null && config.isPublic then
                    # subdomain . public domain
                    "${config.subdomain}.${hlcfg.network.publicDomain}"
                  else
                    null;
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
            };
          }
        )
      );
    };
  };

  config = {
    users.groups = mapAttrs (name: gid: { inherit gid; }) hlcfg.groups;
    containers =
      let
        containerServices = filterAttrs (n: v: v.id != null && v.enable) hlcfg.services;
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
            hostPort = v.port;
            containerPort = v.port;
          }) ([ v.port ] ++ v.extraPorts)
        );
      }) containerServices;

    homelab.services = lib.genAttrs hlcfg.enableServices (name: {
      enable = true;
    });
    homelab.lib = {
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
