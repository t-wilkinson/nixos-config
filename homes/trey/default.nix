let
  username = "trey";
  homeDirectory = "/home/trey";
in
{ pkgs, impurity, ... }: {
  imports = [
    # Cachix
    # ./cachix.nix
    ## Dotfiles (manual)
    ./dotfiles.nix
    # Stuff
    ./ags.nix
    ./anyrun.nix
    ./browser.nix
    ./dconf.nix
    ./hyprland.nix
    ./mimelist.nix
    ./packages.nix
    # ./starship.nix
    ./sway.nix
    ./theme.nix
    ../../modules/lf.nix
  ];

  home = {
    inherit username homeDirectory;
    sessionVariables = {
      FLAKE = "/home/trey/dev/t-wilkinson/nixos";
      NIXPKGS_ALLOW_UNFREE = "1";
      NIXPKGS_ALLOW_INSECURE = "1";
    };
    sessionPath = [
      "$HOME/.local/bin"
    ];
  };

  xdg.userDirs = {
    createDirectories = true;
  };

  gtk = {
    font = {
      name = "Rubik";
      package = pkgs.google-fonts.override { fonts = [ "Rubik" ]; };
      size = 11;
    };
    gtk3 = {
      bookmarks = [
        "file://${homeDirectory}/Downloads"
        "file://${homeDirectory}/Documents"
        "file://${homeDirectory}/Pictures"
        "file://${homeDirectory}/Music"
        "file://${homeDirectory}/Videos"
        "file://${homeDirectory}/.config"
        "file://${homeDirectory}/.config/ags"
        "file://${homeDirectory}/.config/hypr"
        "file://${homeDirectory}/GitHub"
        "file:///mnt/Windows"
      ];
    };
  };

  programs = {
    home-manager.enable = true;
  };
  home.stateVersion = "23.11"; # this must be the version at which you have started using the program
}


#  home-manager = {
#    users.trey = { config, pkgs, ... }: {
#      home = {
#        stateVersion = "23.11"; # Touch this and Covid 2.0 is released
#        username = "trey";
#        homeDirectory = "/home/trey";
#        packages = with pkgs; [
#          firefox
#          (writeShellScriptBin "hello-bro" ''
#            echo "Hello, ${config.home.username}!"
#          '')
#        ];
#        file = {
#          # ".screenrc".source = dotfiles/screenrc;
#          # ".gradle/gradle.properties".text = ''
#          # '';
#        };
#        shellAliases = {
#          vim = "nvim";
#        };
#        sessionVariables = {
#          EDITOR = "nvim";
#        };
#      };
#      programs.git = {
#        enable = true;
#        userName = "t-wilkinson";
#        userEmail = "winston.trey.wilkinson@gmail.com";
#        aliases = {
#          pu = "push";
#          co = "checkout";
#          cm = "commit";
#        };
#      };
#      programs.zsh = {
#      	enable = true;
#	enableAutosuggestions = true;
#	enableCompletion = true;
#      };
#      xdg.mimeApps.defaultApplications = {
#        "application/pdf" = [ "zathura.desktop" ];
#        "image/*" = [ "sxiv.desktop" ];
#      };
#      programs.home-manager.enable = true;
#    };
#  };
