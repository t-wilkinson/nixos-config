{ lib, config, ... }:
with lib;
let
  cfg = config.homelab;
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

    vpnNetwork = mkOption {
      type = types.str;
      default = "10.100.0";
    };
    vpnIP = mkOption {
      type = types.str;
      default = "10.100.0.1";
    };
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
      default = "${cfg.containerNetwork}.1";
    };

    services = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, config, ... }:
          {
            options = {
              port = mkOption { type = types.int; };
              extraPorts = mkOption {
                type = types.listOf types.int;
                default = [ ];
                description = "Additional ports to forward in container";
              };

              id = mkOption {
                type = types.nullOr types.int;
                default = null;
              };
              containerIP = mkOption {
                readOnly = true;
                default =
                  if config.id != null then "${cfg.containerNetwork}.${toString config.id}" else "127.0.0.1";
                type = types.str;
                description = "The calculated internal IP address.";
              };

              expose = mkOption {
                type = types.bool;
                default = true;
              };

              subdomain = mkOption {
                type = types.nullOr types.str;
                default = if config.expose then name else null;
              };
              domain = mkOption {
                type = types.nullOr types.str;
                default = if config.expose then "${config.subdomain}.${cfg.domain}" else null;
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
                    defaultDomain = "${config.subdomain}.${cfg.publicDomain}";
                    publicDomain = "${config.publicSubdomain}.${cfg.publicDomain}";
                  in
                  if cfg.publicDomain != null && config.publicSubdomain != null then
                    # public subdomain . public domain
                    "${config.publicSubdomain}.${cfg.publicDomain}"
                  else if cfg.publicDomain != null && config.isPublic then
                    # subdomain . public domain
                    "${config.subdomain}.${cfg.publicDomain}"
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
    containers =
      let
        containerServices = filterAttrs (n: v: v.id != null) cfg.services;
      in
      mapAttrs (n: v: {
        privateNetwork = true;
        hostAddress = cfg.hostContainerIP;
        localAddress = v.containerIP;
        forwardPorts = lib.mkDefault (
          map (p: {
            protocol = "tcp";
            hostPort = v.port;
            containerPort = v.port;
          }) ([ v.port ] ++ v.extraPorts)
        );
      }) containerServices;
    homelab.lib = {
      mkRoMount = path: {
        "${path}" = {
          hostPath = path;
          isReadOnly = true;
        };
      };

      mkSecretMounts = secretsList: foldl' (acc: s: acc // (cfg.lib.mkRoMount s.path)) { } secretsList;
    };
  };
}
