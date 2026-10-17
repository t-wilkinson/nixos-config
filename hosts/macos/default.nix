{
  pkgs,
  lib,
  username,
  ...
}:
let
  customBuilder = false; # see nix.linux-builder below
in
{
  imports = [
    ./home-manager.nix
    ../../modules/shared.nix
    ./networking.nix
    # ./dock.nix
    # ./podman.nix
  ];

  security.pki.certificateFiles = [
    ../homelab/homelab-root.crt
  ];

  services.openssh.enable = false;

  sops = {
    age.keyFile = "/Users/${username}/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      # wg_macos_private_key = {
      #   owner = "root";
      # };

      # ntfy access token for Neovim (zortex.nvim reads /run/secrets/ntfy_auth).
      # The homelab file is also encrypted to user_key, which this machine holds.
      ntfy_auth = {
        sopsFile = ../homelab/secrets.yaml;
        owner = username;
        mode = "0400";
      };
    };
    age.sshKeyPaths = [ ];
    gnupg.sshKeyPaths = [ ];
  };

  # Was in modules/nix.nix (shared); kept for macOS only, see the note there
  nixpkgs.config.allowUnsupportedSystem = true;

  nix = {
    package = pkgs.nix;
    # Builds aarch64-linux (the Pi) in a small NixOS VM; Nix sends Linux builds to it as a
    # remote builder. Bootstrapping: the VM image is itself a Linux build, so a customised
    # image can't be built until a builder exists. Switch once with customBuilder = false
    # (prebuilt image from cache.nixos.org), then set it to true and switch again.
    # Check: `nix build --impure --expr '(with import <nixpkgs> { system = "aarch64-linux"; }; hello)'`
    # or `sudo ssh linux-builder uname -a`.
    linux-builder = {
      enable = true;
      ephemeral = true;
      maxJobs = 4;
      config = lib.mkIf customBuilder {
        virtualisation = {
          darwin-builder = {
            diskSize = 40 * 1024;
            memorySize = 8 * 1024;
          };
          cores = 4;
        };
      };
    };

    optimise.automatic = true;

    settings = {
      # No Linux entries in extra-platforms: they tell Nix this Mac can build Linux itself, so it
      # tried locally (and failed) instead of using the linux-builder.
      # extra-platforms = [
      #   "aarch64-linux"
      #   "x86_64-linux"
      # ];
      # experimental-features = "nix-command flakes";
      trusted-users = [
        "@admin"
        "root"
        username
      ];
    };

    # extraOptions = ''
    #   experimental-features = nix-command flakes
    # '';

    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 2;
        Minute = 0;
      };
      options = "--delete-older-than 30d";
    };
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

  system = {
    stateVersion = 5;
    primaryUser = username;

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
