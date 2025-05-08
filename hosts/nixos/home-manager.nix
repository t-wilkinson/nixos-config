{ inputs, config, pkgs, myLib, lib, impurity, ... }:
let
  username = "trey";
  homeDirectory = "/home/trey";
  git-credential-pass = pkgs.writeShellScriptBin "git-credential-pass" ''
    #!/bin/bash
    echo "protocol=https"
    token=$(${pkgs.pass}/bin/pass git/token)
    echo "username=t-wilkinson"
    echo "password=$token"
  '';
in {
home-manager.extraSpecialArgs = { inherit inputs; };
  home-manager.users.${username} = {
imports = [
  ./files-old/default.nix
];
    home = {
      inherit username homeDirectory;
      sessionPath = [ "$HOME/.local/bin" "$HOME/.npm-packages/bin" ];
      shellAliases = { vim = "nvim"; };
      packages = [ git-credential-pass ];
      file = myLib.makeConfigLinks impurity [
        "ags"
        "anyrun"
        "chrome-flags.conf"
        "code-flags.conf"
        "fish"
        "fontconfig"
        "foot"
        "fuzzel"
        "hypr"
        # "kitty"
        "Kvantum"
        "mpv"
        "qt5ct"
        "starship.toml"
        "thorium-flags.conf"
        "wlogout"
        "zshrc.d"
      ];
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
          init = { defaultBranch = "main"; };
          credential.helper = "${git-credential-pass}/bin/git-credential-pass";
        };
        aliases = {
          pu = "push";
          co = "checkout";
          cm = "commit";
        };
      };
    };

    xdg.userDirs = { createDirectories = true; };

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
          "file://${homeDirectory}/dev/t-wilkinson/personal/resume"
        ];
      };
    };

    home.stateVersion =
      "24.05"; # this must be the version at which you have started using the program
  };
}
