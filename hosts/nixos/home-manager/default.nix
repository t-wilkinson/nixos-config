{
  self,
  inputs,
  config,
  pkgs,
  myLib,
  lib,
  impurity,
  username,
  hostname,
  ...
}:
let
  homeDirectory = "/home/${username}";
  git-credential-pass = pkgs.writeShellScriptBin "git-credential-pass" ''
    #!/bin/bash
    echo "protocol=https"
    token=$(${pkgs.pass}/bin/pass git/token)
    echo "username=t-wilkinson"
    echo "password=$token"
  '';
in
{
  home-manager = {
    verbose = true;
    useGlobalPkgs = true; # use the system configuration’s pkgs argument
    useUserPackages = true; # enable users.users.<name>.packages
    backupFileExtension = "old";
    extraSpecialArgs = {
      inherit
        self
        username
        inputs
        impurity
        ;
    };
    users.${username} = {
      imports = [
        ./ags.nix
        ./anyrun.nix
        ./browser.nix
        ./dconf.nix
        ./hyprland.nix
        ./mimelist.nix
        ./packages.nix
        ./sway.nix
        ./theme.nix
      ];
      home = {
        inherit username homeDirectory;
        # TODO: doesn't work
        sessionPath = [
          "$HOME/.local/bin"
          "$HOME/.npm-packages/bin"
        ];
        packages = [ git-credential-pass ];
        file =
          myLib.makeConfigLinks impurity [
            "ags"
            # "chrome-flags.conf"
            # "code-flags.conf"
            # "fontconfig"
            "fuzzel"
            "hypr"
            # "Kvantum"
            "mpv"
            # "qt5ct"
            "fcitx5"
            "thorium-flags.conf"
            # "wlogout"
            # "zshrc.d"
          ]
          // {
            # TODO: add linux-specific gpg-agent later
            # ".gnupg/gpg-agent.conf".source = "${self}${homeDirectory}/.gnupg/gpg-agent.conf.linux";
          };
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
            # "file://${homeDirectory}/dev/t-wilkinson/personal/resume"
          ];
        };
      };

      home.stateVersion = "24.05"; # this must be the version at which you have started using the program
    };
  };
}
