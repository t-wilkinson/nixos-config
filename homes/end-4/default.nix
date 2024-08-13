{ config, pkgs, lib, impurity, ... }:
let
  username = "end-4";
  homeDirectory = "/home/end-4";
  git-credential-pass = pkgs.writeShellScriptBin "git-credential-pass" ''
    #!/bin/bash
    echo "protocol=https"
    token=$(${pkgs.pass}/bin/pass git/token)
    echo "username=t-wilkinson"
    echo "password=$token"
  '';
in
{
  imports = [
    # ./cachix.nix
    ./dotfiles.nix
    ../../modules/homes/lf.nix

    # CONFIG
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
    packages = [
      git-credential-pass
    ];
    file."my".source = config.lib.file.mkOutOfStoreSymlink "${homeDirectory}/dev/t-wilkinson";
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
      extraConfig = {
        init = {
          defaultBranch = "main";
        };
        credential.helper = "${git-credential-pass}/bin/git-credential-pass";
      };
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

  # dconf.settings = {
  #   "org/virt-manager/virt-manager/connections" = {
  #     autoconnect = ["qemu:///system"];
  #     uris = ["qemu:///system"];
  #   };
  # };

  gtk = {
    font = {
      name = "Rubik";
      package = pkgs.google-fonts.override { fonts = [ "Rubik" ]; };
      size = 11;
    };
    gtk3 = {
      bookmarks = [
        "file://${homeDirectory}/dev"
        "file://${homeDirectory}/dev/t-wilkinson"
        "file://${homeDirectory}/Downloads"
        "file://${homeDirectory}/Documents"
        "file://${homeDirectory}/.config"
      ];
    };
  };

  home.stateVersion = "24.05"; # this must be the version at which you have started using the program
}
