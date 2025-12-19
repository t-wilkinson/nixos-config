{ pkgs, ... }:
{
  # sound.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # jack.enable = true;
    wireplumber.enable = true;
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
