{ pkgs, impurity, ... }:
let
  username = "trey";
  homeDirectory = "/home/trey";
in
{
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
    ../../modules/homes/lf.nix
  ];

  home = {
    inherit username homeDirectory;
    # sessionVariables = { # doesn't seem to work
    #   NIXPKGS_ALLOW_UNFREE = "1";
    #   NIXPKGS_ALLOW_INSECURE = "1";
    #   FLAKE = "$HOME/dev/t-wilkinson/nixos";
    #   NODE_PATH = "$HOME/.npm-packages/lib/node_modules";
    # };
    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.npm-packages/bin"
    ];
    shellAliases = {
      vim = "nvim";
    };
    # file = {
    #   ".screenrc".source = dotfiles/screenrc;
    #   ".gradle/gradle.properties".text = ''
    #   '';
    # };
  };

  programs = {
    home-manager.enable = true;
    # fish.enable = true;
    # zsh = {
    #   enable = true;
    #   enableAutosuggestions = true;
    #   enableCompletion = true;
    # };
    git = {
      enable = true;
      userName = "t-wilkinson";
      userEmail = "winston.trey.wilkinson@gmail.com";
      aliases = {
        pu = "push";
        co = "checkout";
        cm = "commit";
      };
    };
  };

  xdg.userDirs = {
    createDirectories = true;
  };

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
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

  home.stateVersion = "23.11"; # this must be the version at which you have started using the program
}
