{ pkgs, ... }:
{
  # sound.enable = true;
  boot.kernelParams = [ "btusb.enable_autosuspend=n" ];

  security.rtkit.enable = true;

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
        # "monitor.bluez.properties" = {
        #   "bluez5.enable-sbc-xq" = true;
        #   "bluez5.enable-msbc" = true;
        #   "bluez5.enable-hw-volume" = true;
        #   "bluez5.roles" = [
        #     "hsp_hs"
        #     "hsp_ag"
        #     "hfp_hf"
        #     "hfp_ag"
        #   ];
        # };
        # "monitor.bluez.rules" = [
        #   {
        #     matches = [ { "node.name" = "~bluez_output.*"; } ];
        #     actions = {
        #       update-props = {
        #         "session.suspend-timeout-seconds" = 0; # 0 disables suspend
        #       };
        #     };
        #   }
        # ];
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
    powerOnBoot = true;
    # settings = {
    #   General = {
    #     Enable = "Source,Sink,Media,Socket";
    #     Experimental = true; # Enables some modern features that improve stability
    #     FastConnectable = true;
    #   };
    # };
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
