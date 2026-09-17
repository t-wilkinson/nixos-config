{ config, pkgs, ... }:
let
  homelab = config.homelab;
  cfg = config.homelab.services.nextcloud;
  secrets = config.sops.secrets;
in
{
  services.nginx.virtualHosts."${cfg.domain}" = {
    listen = [
      {
        addr = "0.0.0.0";
        port = cfg.port;
      }
    ];
  };

  users.users.nextcloud.extraGroups = [
    "serverdata"
    "personaldata"
  ];

  systemd.services.phpfpm-nextcloud.serviceConfig = {
    ReadWritePaths = [
      "/mnt/storage/pubdrive"
    ];
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud32;
    hostName = cfg.domain;
    https = true;
    configureRedis = true;
    database.createLocally = true;
    # datadir = "/mnt/storage/pubdrive";

    config = {
      adminuser = "admin";
      adminpassFile = secrets.nextcloud_admin_pass.path;
      dbtype = "pgsql";
      # dbname = "nextcloud";
      # dbhost = "/run/postgresql";
    };

    settings = {
      "enable_previews" = true;
      "preview_max_x" = 1024;
      "preview_max_y" = 1024;
      "preview_max_filesize_image" = 50;
      overwriteprotocol = "https";
      overwritehost = cfg.publicDomain;
      trusted_domains = [
        cfg.localIP
        cfg.domain
        cfg.publicDomain
        homelab.nodes.pi.ipv4
        homelab.nodes.pc.ipv4
        "127.0.0.1"
      ];
      trusted_proxies = [
        "127.0.0.1"
        homelab.nodes.pi.ipv4
      ];

      preview_ffmpeg_path = "${pkgs.ffmpeg}/bin/ffmpeg";
      enabledPreviewProviders = [
        "OC\\Preview\\Movie"
        "OC\\Preview\\MP4"
        "OC\\Preview\\HEIC"
        "OC\\Preview\\PNG"
        "OC\\Preview\\JPEG"
        "OC\\Preview\\WebP"
      ];

    };

  };
}
