{ config, lib, ... }:
let
  homelab = config.homelab;
  services = config.homelab.services;
  enabled = services.glances.enable or services.prometheus.enable or services.grafana.enable;
in
{
  config = lib.mkIf enabled {
    containers.monitor = {
      autoStart = true;
      bindMounts = {
        "/var/log" = {
          hostPath = "/var/log";
          isReadOnly = false;
        };
      };

      config = {
        # GLANCES
        services.glances = lib.mkIf services.glances.enable {
          enable = true;
          port = services.glances.port;
          extraArgs = [ "-w" ];
        };

        # PROMETHEUS
        services.prometheus = lib.mkIf services.prometheus.enable {
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
        services.grafana = lib.mkIf services.grafana.enable {
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
  };
}
