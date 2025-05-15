{
  self,
  config,
  pkgs,
  username,
  ...
}:
{
  imports = [
    # "${self}/modules/darwin/secrets.nix"
    ./home-manager.nix
    ../../modules/shared.nix
    ./packages.nix
    # agenix.darwinModules.default
  ];

  # environment.systemPackages = with pkgs; [
  #   # agenix.packages."${pkgs.system}".default
  # ];

  # TODO: similarly defined in modules/shared/cachix.nix?
  nix = {
    package = pkgs.nix;
    # linux-builder.enable = true;

    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [
        "@admin"
        username
      ];
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
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

  # Turn off NIX_PATH warnings because we're using flakes
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

  # networking.wireguard.enable = true;
  # networking.wireguard.interfaces = {
  #   # "wg0" is the network interface name. You can name the interface arbitrarily.
  #   wg0 = {
  #     # Determines the IP address and subnet of the client's end of the tunnel interface.
  #     ips = [ "10.100.0.2/24" ];
  #     listenPort = 51820; # to match firewall allowedUDPPorts (without this wg uses random port numbers)

  #     # Path to the private key file.
  #     #
  #     # Note: The private key can also be included inline via the privateKey option,
  #     # but this makes the private key world-readable; thus, using privateKeyFile is
  #     # recommended.
  #     privateKeyFile = "path to private key file";

  #     peers = [
  #       # For a client configuration, one peer entry for the server will suffice.

  #       {
  #         # Public key of the server (not a file path).
  #         publicKey = "{server public key}";

  #         # Forward all the traffic via VPN.
  #         allowedIPs = [ "0.0.0.0/0" ];
  #         # Or forward only particular subnets
  #         #allowedIPs = [ "10.100.0.1" "91.108.12.0/22" ];

  #         # Set this to the server IP and port.
  #         endpoint = "{server ip}:51820"; # ToDo: route to endpoint not automatically configured https://wiki.archlinux.org/index.php/WireGuard#Loop_routing https://discourse.nixos.org/t/solved-minimal-firewall-setup-for-wireguard-client/7577

  #         # Send keepalives every 25 seconds. Important to keep NAT tables alive.
  #         persistentKeepalive = 25;
  #       }
  #     ];
  #   };
  # };

  system = {
    stateVersion = 5;

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
