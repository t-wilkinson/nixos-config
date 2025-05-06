{ config, pkgs, lib, home-manager, ... }:

let
  user = "trey";
  # sharedFiles = import ../../shared/files.nix { inherit config pkgs; };
in
{
  imports = [
   # ./dock.nix
  ];

  # It me
  users.users.${user} = {
    name = "${user}";
    home = "/Users/${user}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  homebrew = {
    enable = true;
    casks = pkgs.callPackage ./casks.nix {};

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
    # extraSpecialArgs = { inherit pkgs-unstable; }; # { inherit inputs self impurity; };
    useGlobalPkgs = true;
    users.${user} = { pkgs, config, lib, ... }:{
      home = {
        enableNixpkgsReleaseCheck = false;
        # packages = pkgs.callPackage ./packages.nix {};
        packages = with pkgs; [
    	    fswatch
    	    dockutil
    	  ];
        file = lib.mkMerge [
          # sharedFiles
        ];

        stateVersion = "23.11";
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
