{
  pkgs,
  username,
  hostname,
  ...
}:
{
  imports = [
    ./home-manager.nix
    ../../modules/shared.nix
    ./networking.nix
  ];

  services.openssh.enable = false;
  sops = {
    age.keyFile = "/Users/${username}/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      wg_macos_private_key = {
        owner = "root";
      };
    };
    gnupg.sshKeyPaths = [ ];
  };

  nix = {
    package = pkgs.nix;
    # linux-builder.enable = true;
    optimise.automatic = true;

    settings = {
      trusted-users = [
        "@admin"
        username
      ];
    };

    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 2;
        Minute = 0;
      };
      options = "--delete-older-than 30d";
    };

    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  programs = {
    fish.enable = true;
  };

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

  networking.hostName = hostname;

  system = {
    stateVersion = 5;
    primaryUser = "trey";

    # Turn off NIX_PATH warnings because we're using flakes
    checks.verifyNixPath = false;

    activationScripts.useTouchID.text = ''
      defaults write org.gpgtools.common UseKeychain -bool yes
      defaults write org.gpgtools.use-gpg-agent UseKeychain -bool yes
    '';

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
