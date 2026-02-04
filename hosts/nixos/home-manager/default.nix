{
  self,
  inputs,
  pkgs,
  myLib,
  impurity,
  homedir,
  username,
  unstable,
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
        unstable
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
        sessionPath = [
          "$HOME/dev/t-wilkinson/personal/scripts"
          "$HOME/dev/t-wilkinson/projects/scripts"
          "$HOME/.local/bin"
          "$HOME/.npm-packages/bin"
        ];
        packages = [ git-credential-pass ];
        file =
          myLib.makeConfigLinks impurity [
            "Kvantum"
            "ags"
            "chrome-flags.conf"
            "code-flags.conf"
            "fcitx5"
            # "fontconfig"
            "fuzzel"
            "hypr"
            "mpv"
            "qt5ct"
            "rofi"
            "thorium-flags.conf"
            "zshrc.d"
            # "wlogout"
          ]
          // {
            # TODO: add linux-specific gpg-agent later
            # ".gnupg/gpg-agent.conf".source = "${homedir}/.gnupg/gpg-agent.conf.linux";
          };
      };

      programs = {
        home-manager.enable = true;
        gpg = {
          enable = true;
          # extraConfig = ''
          #   default-cache-ttl 34560000
          #   max-cache-ttl 34560000
          # '';
        };
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
            "file://${homeDirectory}/dev/t-wilkinson/zortex.nvim"
            "file://${homeDirectory}/dev/t-wilkinson/nixos-config"
            "file://${homeDirectory}/dev/t-wilkinson/personal"
            "file://${homeDirectory}/Downloads"
            "file://${homeDirectory}/Documents"
            "file://${homeDirectory}/.config"
            "file:///tmp/flatten"
          ];
        };
      };

      home.stateVersion = "24.05"; # this must be the version at which you have started using the program
    };
  };
}
