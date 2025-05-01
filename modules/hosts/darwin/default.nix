{ self, agenix, config, pkgs, ... }:

let user = "trey";
in {
  imports = [
    # "${self}/modules/darwin/secrets.nix"
    ../../shared
    ./home-manager
    # agenix.darwinModules.default
  ];

  environment.systemPackages = with pkgs; [
    # agenix.packages."${pkgs.system}".default
  ] ++ (import ../../modules/shared/packages.nix { inherit pkgs; });

  nix = {
    package = pkgs.nix;

    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [ "@admin" "${user}" ];
      substituters =
        [ "https://cache.nixos.org" "https://nix-community.cachix.org" ];
      trusted-public-keys =
        [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
    };

    gc = {
      automatic = true;
      interval = { Weekday = 0; Hour = 2; Minute = 0; };
      options = "--delete-older-than 30d";
    };

    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Turn off NIX_PATH warnings now that we're using flakes
  system.checks.verifyNixPath = false;

  # launchd.user.agents = {
  #   emacs = {
  #     path = [ config.environment.systemPath ];
  #     serviceConfig = {
  #       KeepAlive = true;
  #       ProgramArguments = [
  #         "/bin/sh"
  #         "-c"
  #         "{ osascript -e 'display notification \"Attempting to start Emacs...\" with title \"Emacs Launch\"'; /bin/wait4path ${pkgs.emacs}/bin/emacs && { ${pkgs.emacs}/bin/emacs --fg-daemon; if [ $? -eq 0 ]; then osascript -e 'display notification \"Emacs has started.\" with title \"Emacs Launch\"'; else osascript -e 'display notification \"Failed to start Emacs.\" with title \"Emacs Launch\"' >&2; fi; } } &> /tmp/emacs_launch.log"
  #       ];
  #       StandardErrorPath = "/tmp/emacs.err.log";
  #       StandardOutPath = "/tmp/emacs.out.log";
  #     };
  #   };
  # };

  system = {
    stateVersion = 4;

    defaults = {
      LaunchServices = {
        # LSQuarantine = false;
      };

      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        # ApplePressAndHoldEnabled = false;

        # 120, 90, 60, 30, 12, 6, 2
        KeyRepeat = 2;

        # 120, 94, 68, 35, 25, 15
        InitialKeyRepeat = 15;

        # "com.apple.mouse.tapBehavior" = 1;
        # "com.apple.sound.beep.volume" = 0.0;
        # "com.apple.sound.beep.feedback" = 0;
      };

      dock = {
        autohide = true;
        # show-recents = false;
        launchanim = true;
        # mouse-over-hilite-stack = true;
        orientation = "bottom";
        tilesize = 48;
      };

      finder = {
        # _FXShowPosixPathInTitle = false;
      };

      trackpad = {
        # Clicking = true;
        # TrackpadThreeFingerDrag = true;
      };
    };

    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };
  };
}
