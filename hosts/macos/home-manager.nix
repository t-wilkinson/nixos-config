{
  self,
  config,
  inputs,
  impurity,
  pkgs,
  unstable,
  lib,
  home-manager,
  homedir,
  username,
  hostname,
  ...
}:
{
  users.knownUsers = [ username ];
  users.users.${username} = {
    uid = 501;
    name = username;
    home = homedir;
    isHidden = false;
    shell = pkgs.fish;
  };

  homebrew = {
    enable = true;
    casks = pkgs.callPackage ./casks.nix { };
    taps = [
      # taps don't work when homebrew is managed by nix (homebrew.enable = true;)
      # Must set homebrew.enable = false; to take /opt/homebrew/Library out of nixstore
      # "jorgelbg/tap"
    ];
    brews = [
      "ntfy"
      "terminal-notifier"
      "bitwarden-cli"
      "pinentry"
      "pinentry-mac"
      # "pinentry-touchid"
      "whalebrew"
    ];

    # These app IDs are from using the mas CLI app
    # mas = mac app store
    # https://github.com/mas-cli/mas
    #
    # $ nix shell nixpkgs#mas
    # $ mas search <app name>
    #
    # masApps = {
    #   "hidden-bar" = 1452453066;
    #   "wireguard" = 1451685025;
    # };
  };

  # Enable home-manager
  home-manager = {
    verbose = true;
    # useUserPackages = true;
    # backupFileExtension = "old";
    backupFileExtension = "old";
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit
        self
        inputs
        username
        unstable
        impurity
        ;
    };
    users.${username} =
      {
        pkgs,
        config,
        lib,
        ...
      }:
      {
        # services.kdeconnect.enable = true;
        # programs.fish.enable = true;
        home = {
          enableNixpkgsReleaseCheck = false;
          # packages = pkgs.callPackage ./packages.nix {};
          packages = with pkgs; [
            fswatch
            dockutil
            prismlauncher
          ];
          file = {
            ".gnupg/gpg-agent.conf".source = "${homedir}/.gnupg/gpg-agent.conf.mac";
          };

          stateVersion = "23.11";
        };

        services.syncthing = {
          enable = true;
          # user = "trey";
          # dataDir = "/Users/trey/.local/state/syncthing"; # Default folder for new synced directories
          # configDir = "/Users/trey/.config/syncthing";

          # openDefaultPorts = true; # 22000/tcp transfer, 21027/udp discovery

          settings = {
            devices = {
              "homelab" = {
                id = "HIAD4WE-UUAOBRY-KXKOWTA-P5HAXBL-FH3NQKF-BZLSGSO-YKNVFFI-4VUZQQE";
                # addresses = [ "tcp://10.1.0.2:22000" ];
              };
            };

            folders = {
              "personal" = {
                id = "personal"; # remove this line?
                path = "/Users/trey/dev/t-wilkinson/personal";
                devices = [ "homelab" ];
              };
            };
          };
        };

        # programs = {} // import ../../shared/home-manager.nix { inherit config pkgs lib; };
      };
  };

  # Fully declarative dock using the latest from Nix Store
  # local = {
  #   dock.enable = true;
  #   dock.entries = [
  #     { path = "/Applications/Slack.app/"; }
  #     { path = "/System/Applications/Messages.app/"; }
  #     { path = "/System/Applications/Facetime.app/"; }
  #     { path = "/Applications/Telegram.app/"; }
  #     { path = "${pkgs.alacritty}/Applications/Alacritty.app/"; }
  #     { path = "/System/Applications/Music.app/"; }
  #     { path = "/System/Applications/News.app/"; }
  #     { path = "/System/Applications/Photos.app/"; }
  #     { path = "/System/Applications/Photo Booth.app/"; }
  #     { path = "/System/Applications/TV.app/"; }
  #     { path = "${pkgs.jetbrains.phpstorm}/Applications/PhpStorm.app/"; }
  #     { path = "/Applications/TablePlus.app/"; }
  #     { path = "/Applications/Asana.app/"; }
  #     { path = "/Applications/Drafts.app/"; }
  #     { path = "/System/Applications/Home.app/"; }
  #     { path = "/Applications/iPhone Mirroring.app/"; }
  #     {
  #       path = toString myEmacsLauncher;
  #       section = "others";
  #     }
  #     {
  #       path = "${config.users.users.${user}.home}/.local/share/";
  #       section = "others";
  #       options = "--sort name --view grid --display folder";
  #     }
  #     {
  #       path = "${config.users.users.${user}.home}/.local/share/downloads";
  #       section = "others";
  #       options = "--sort name --view grid --display stack";
  #     }
  #   ];
  # };
}
