{ pkgs, ... }:
{
  # sound.enable = true;
  boot.kernelParams = [ "btusb.enable_autosuspend=n" ];

  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # jack.enable = true;
    wireplumber.enable = true;

    wireplumber.extraConfig = {
      "10-disable-suspend" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              {
                # Matches all sources
                "node.name" = "~alsa_input.*";
              }
              {
                # Matches all sinks
                "node.name" = "~alsa_output.*";
              }
            ];
            actions = {
              update-props = {
                "session.suspend-on-idle" = false;
              };
            };
          }
        ];
      };
    };
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  systemd.services.pipewire-restart-on-resume = {
    description = "Restart PipeWire after suspend";
    wantedBy = [ "sleep.target" ];
    after = [ "sleep.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = [
        "${pkgs.systemd}/bin/systemctl --user restart pipewire.service"
        "${pkgs.systemd}/bin/systemctl --user restart wireplumber.service"
      ];
    };
  };
}
