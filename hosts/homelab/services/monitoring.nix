{ config, ... }:
let
  services = config.my-lab.services;
in
{

  containers.monitor = {
  autoStart = true;
    bindMounts = [
      "/var/log" = {
        hostPath = "/var/log";
        isReadOnly = true;
      };
    ];

    config = {
      # GLANCES
      services.glances = {
        enable = true;
        extraArgs = [ "-w" ];
      };

      # PROMETHEUS
      services.prometheus = {
        enable = true;
        port = services.prometheus.port;
        exporters = {
          node = {
            enable = true;
            enabledCollectors = [ "systemd" ];
            port = 9100;
          };
        };
        # Scrape locally
        scrapeConfigs = [
          {
            job_name = "homelab";
            static_configs = [
              {
                targets = [ "127.0.0.1:9100" ];
              }
            ];
          }
        ];
      };

      # GRAFANA
      services.grafana = {
        enable = true;
        settings = {
          server = {
            http_addr = "127.0.0.1";
            http_port = services.grafana.port;
            domain = services.grafana.domain;
          };
        };
        # Automatically add Prometheus as a data source
        provision.datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:${toString services.prometheus.port}";
          }
        ];
      };
    };
  };
}
