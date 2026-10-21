{
  self,
  inputs,
  pkgs,
  myLib,
  configDir,
  homedir,
  username,
  unstable,
  ...
}:
let
  homeDirectory = "/home/${username}";
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
        # Git and SSH authenticate with keys stored in Vaultwarden, served by the Bitwarden
        # desktop app's SSH agent (it asks before each use). Hyprland sets it too (env.conf).
        sessionVariables.SSH_AUTH_SOCK = "${homeDirectory}/.bitwarden-ssh-agent.sock";
        file =
          myLib.mkConfigLinks pkgs configDir [
            "Kvantum"
            "ags"
            "chrome-flags.conf"
            "code-flags.conf"
            "fcitx5"
            # "fontconfig"
            "fuzzel"
            "hypr"
            "mpv"
            "ntfy"
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
          # 26.05: userName/userEmail/extraConfig/aliases all live under settings
          settings = {
            user = {
              name = "t-wilkinson";
              email = "winston.trey.wilkinson@gmail.com";
            };
            init = {
              defaultBranch = "main";
            };
            # Your own repos go over SSH (key from the Bitwarden agent, no stored token);
            # everyone else's stay anonymous HTTPS. Flake inputs (github:...) are unaffected.
            url."git@github.com:t-wilkinson/".insteadOf = "https://github.com/t-wilkinson/";
            alias = {
              pu = "push";
              co = "checkout";
              cm = "commit";
            };
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
            "file:///${homeDirectory}/.cache/flatten"
          ];
        };
      };

      home.stateVersion = "24.05"; # this must be the version at which you have started using the program
    };
  };
}
