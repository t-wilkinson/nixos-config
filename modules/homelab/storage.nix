# modules/homelab/storage.nix
#
# Where data lives, declared once in hosts/inventory.nix and turned into config on each node:
#
#   homelab.storage.volumes.<volume>            a disk (or a plain directory) on one node
#     .node, .mountPoint, .device / .uuid, .fsType, .options
#     .shares.<share>                           a directory on that volume
#       .owner, .group, .mode, .recursive       -> systemd.tmpfiles on the volume's node
#       .nfs.<client node> = { mountPoint; }    -> an NFS export on the volume's node and an
#                                                  automounted NFS mount on the client node
#
# Other modules look shares up by name, without caring which volume or node holds them:
#
#   homelab.storage.shares.<share>.path         the path on the node that holds the share
#   homelab.storage.shares.<share>.localPath    the path as seen from this node (the share
#                                               itself, its NFS mount here, or null)
#   homelab.storage.shares.<share>.node         which node holds it
#
# Share names are unique across all volumes.
{ config, lib, ... }:
let
  inherit (lib) mkOption types;
  hl = config.homelab;
  cfg = hl.storage;

  # Default options for NFS client mounts: mounted on first access, unmounted when the
  # server goes away, and never holding up boot when the other node is asleep.
  nfsClientOptions = [
    "x-systemd.automount"
    "noauto"
    "_netdev"
    "x-systemd.after=network-online.target"
    "x-systemd.mount-timeout=10s"
  ];

  shareModule =
    volume:
    { name, config, ... }:
    {
      options = {
        subpath = mkOption {
          type = types.str;
          default = name;
          description = "Directory inside the volume (may contain slashes).";
        };
        path = mkOption {
          type = types.str;
          readOnly = true;
          default = "${volume.mountPoint}/${config.subpath}";
          description = "Full path on the volume's node.";
        };

        owner = mkOption {
          type = types.str;
          default = hl.username;
        };
        group = mkOption {
          type = types.str;
          default = "-";
          description = "Group name (see homelab.groups), or \"-\" to leave it alone.";
        };
        mode = mkOption {
          type = types.str;
          default = "0750";
          example = "2770";
        };
        recursive = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Re-apply owner, group and mode to everything inside on every boot and switch
            (tmpfiles Z). Off: only the directory itself is fixed (tmpfiles z). Leave off for
            directories other users or services write into with their own ownership.
          '';
        };

        nfs = mkOption {
          default = { };
          example = {
            pi.mountPoint = "/srv/pubdrive";
          };
          description = "Nodes that mount this share over NFS, and where.";
          type = types.attrsOf (
            types.submodule {
              options = {
                mountPoint = mkOption { type = types.str; };
                options = mkOption {
                  type = types.listOf types.str;
                  default = nfsClientOptions;
                  description = "Mount options on the client.";
                };
                extraOptions = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                  example = [ "soft" ];
                  description = "Added to options.";
                };
                exportOptions = mkOption {
                  type = types.str;
                  default = "rw,sync,no_subtree_check,no_root_squash";
                  description = "/etc/exports options for this client.";
                };
              };
            }
          );
        };
      };
    };

  volumeModule =
    { name, config, ... }:
    {
      options = {
        node = mkOption {
          type = types.str;
          example = "pc";
          description = "Node in homelab.nodes that holds this volume.";
        };
        mountPoint = mkOption {
          type = types.str;
          description = "Where the volume is mounted (or, with no device, the directory that holds its shares).";
        };
        uuid = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Filesystem UUID; sets device to /dev/disk/by-uuid/<uuid>.";
        };
        device = mkOption {
          type = types.nullOr types.str;
          default = if config.uuid == null then null else "/dev/disk/by-uuid/${config.uuid}";
          description = ''
            Block device to mount at mountPoint. null: the volume is a directory on a filesystem
            that is already mounted (e.g. the root filesystem), so no mount is generated.
          '';
        };
        fsType = mkOption {
          type = types.str;
          default = "ext4";
        };
        options = mkOption {
          type = types.listOf types.str;
          default = [
            "defaults"
            "nofail"
          ];
        };
        shares = mkOption {
          default = { };
          type = types.attrsOf (types.submodule (shareModule config));
          description = "Named directories on this volume.";
        };
      };
    };

  localVolumes = lib.filterAttrs (n: v: v.node == hl.thisNode) cfg.volumes;
  allShares = lib.concatMapAttrs (
    vname: v: lib.mapAttrs (sname: s: s // { inherit vname; inherit (v) node; }) v.shares
  ) cfg.volumes;
  localShares = lib.filterAttrs (n: s: s.node == hl.thisNode) allShares;
  mountedHere = lib.filterAttrs (n: s: s.nfs ? ${hl.thisNode}) allShares;
  exportedHere = lib.filterAttrs (n: s: s.nfs != { }) localShares;
  shareNames = lib.concatMap (v: lib.attrNames v.shares) (lib.attrValues cfg.volumes);
in
{
  options.homelab.storage = {
    volumes = mkOption {
      default = { };
      type = types.attrsOf (types.submodule volumeModule);
      description = "Disks and data directories on every node.";
    };
    shares = mkOption {
      readOnly = true;
      description = "Every share by name: { node, volume, path, localPath, ... }.";
      type = types.attrsOf types.attrs;
      default = lib.mapAttrs (
        n: s:
        {
          inherit (s)
            node
            path
            owner
            group
            mode
            ;
          volume = s.vname;
          localPath =
            if s.node == hl.thisNode then
              s.path
            else if s.nfs ? ${hl.thisNode} then
              s.nfs.${hl.thisNode}.mountPoint
            else
              null;
        }
      ) allShares;
    };
  };

  config = {
    assertions = [
      {
        assertion = lib.length shareNames == lib.length (lib.unique shareNames);
        message = "homelab.storage: share names must be unique across volumes (${toString shareNames}).";
      }
    ]
    ++ lib.mapAttrsToList (n: v: {
      assertion = hl.nodes ? ${v.node};
      message = "homelab.storage.volumes.${n}.node = \"${v.node}\" is not in homelab.nodes.";
    }) cfg.volumes
    ++ lib.concatLists (
      lib.mapAttrsToList (
        n: s:
        lib.mapAttrsToList (client: _: {
          assertion = hl.nodes ? ${client} && hl.nodes.${client}.ipv4 != null && hl.nodes.${s.node}.ipv4 != null;
          message = "homelab.storage share ${n}: NFS between ${s.node} and ${client} needs both nodes' ipv4.";
        }) s.nfs
      ) allShares
    );

    # Volumes with a device on this node
    fileSystems =
      lib.mapAttrs' (
        n: v:
        lib.nameValuePair v.mountPoint {
          inherit (v) device fsType options;
        }
      ) (lib.filterAttrs (n: v: v.device != null) localVolumes)

      # Shares from other nodes mounted here over NFS
      // lib.mapAttrs' (
        n: s:
        let
          c = s.nfs.${hl.thisNode};
        in
        lib.nameValuePair c.mountPoint {
          device = "${hl.nodes.${s.node}.ipv4}:${s.path}";
          fsType = "nfs";
          options = c.options ++ c.extraOptions;
        }
      ) mountedHere;

    systemd.tmpfiles.rules = lib.concatLists (
      lib.mapAttrsToList (n: s: [
        "d ${s.path} ${s.mode} ${s.owner} ${s.group} - -"
        "${if s.recursive then "Z" else "z"} ${s.path} ${s.mode} ${s.owner} ${s.group} - -"
      ]) localShares
    );

    services.nfs.server = lib.mkIf (exportedHere != { }) {
      enable = true;
      exports = lib.concatLines (
        lib.mapAttrsToList (
          n: s:
          "${s.path} "
          + lib.concatStringsSep " " (
            lib.mapAttrsToList (client: c: "${hl.nodes.${client}.ipv4}(${c.exportOptions})") s.nfs
          )
        ) exportedHere
      );
    };
  };
}
