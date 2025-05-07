{ self, config, impurity, pkgs, unstable, myLib, ... }:

let
  name = "Trey Wilkinson";
  user = "trey";
  email = "winston.trey.wilkinson@gmail.com";
in
{
  home-manager.users.${user} = {
    home = {
      packages = []
        ++ (import ./packages.nix { inherit pkgs unstable; })
        ++ (import ./development.nix { inherit pkgs unstable; })
        ;
      file = myLib.makeConfigLinks impurity [
          "nvim"
          "zellij"
          "kitty"
        ];
    };

    programs = {
      direnv = {
          enable = true;
          enableZshIntegration = true;
          nix-direnv.enable = true;
      };

      zsh = {
        enable = true;
      # autocd = false;
      # cdpath = [ "~/.local/share/src" ];
      # plugins = [
      #    {
      #        name = "powerlevel10k";
      #        src = pkgs.zsh-powerlevel10k;
      #        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      #    }
      #    {
      #        name = "powerlevel10k-config";
      #        src = lib.cleanSource ./config;
      #        file = "p10k.zsh";
      #    }
      #  ];
        initExtraFirst = ''
          export KITTY_CONFIG_DIRECTORY="/Users/${user}/.config/kitty"
          export PROMPT="%B%F{#6e6a86}%~%f%b %B%F{#3e8fb0}λ%b%f "
          export NIX_PATH=""
          [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh 
          alias vim=nvim
          # if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
          #   . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
          #   . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
          # fi

          # if [[ "$(uname)" == "Linux" ]]; then
          #   alias pbcopy='xclip -selection clipboard'
          # fi

          # # Define variables for directories
          # export PATH=$HOME/.pnpm-packages/bin:$HOME/.pnpm-packages:$PATH
          # export PATH=$HOME/.npm-packages/bin:$HOME/bin:$PATH
          # export PATH=$HOME/.composer/vendor/bin:$PATH
          # export PATH=$HOME/.local/share/bin:$PATH

          # # Remove history data we don't want to see
          # export HISTIGNORE="pwd:ls:cd"

          # # Ripgrep alias
          # alias search='rg -p --glob "!node_modules/*" --glob "!vendor/*" "$@"'

          # # Emacs is my editor
          # export ALTERNATE_EDITOR=""
          # export EDITOR="emacsclient -t"
          # export VISUAL="emacsclient -c -a emacs"
          # e() {
          #     emacsclient -t "$@"
          # }

          # # Laravel Artisan
          # alias art='php artisan'

          # # PHP Deployer
          # alias deploy='dep deploy'

          # # Easy alias to trim whitespace from files on macOS
          # alias trimwhitespace="find . -type f \( -name '*.jsx' -o -name '*.php' -o -name '*.js' \) -exec sed -i \"\" 's/[[:space:]]*\$//' {} +"

          # # Use difftastic, syntax-aware diffing
          # alias diff=difft

          # # Always color ls and group directories
          # alias ls='ls --color=auto'

          # # Reboot into my dual boot Windows partition
          # alias windows='systemctl reboot --boot-loader-entry=auto-windows'
        '';
      };

      # git = {
      #   enable = true;
      #   ignores = [ "*.swp" ];
      #   userName = name;
      #   userEmail = email;
      #   lfs = {
      #     enable = true;
      #   };
      #   extraConfig = {
      #     init.defaultBranch = "main";
      #     core = {
      #           editor = "vim";
      #       autocrlf = "input";
      #     };
      #     commit.gpgsign = true;
      #     pull.rebase = true;
      #     rebase.autoStash = true;
      #   };
      # };

      # ssh = {
      #   enable = true;
      #   includes = [
      #     (lib.mkIf pkgs.stdenv.hostPlatform.isLinux
      #       "/home/${user}/.ssh/config_external"
      #     )
      #     (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
      #       "/Users/${user}/.ssh/config_external"
      #     )
      #   ];
      #   matchBlocks = {
      #     "github.com" = {
      #       identitiesOnly = true;
      #       identityFile = [
      #         (lib.mkIf pkgs.stdenv.hostPlatform.isLinux
      #           "/home/${user}/.ssh/id_github"
      #         )
      #         (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
      #           "/Users/${user}/.ssh/id_github"
      #         )
      #       ];
      #     };
      #   };
      # };
    };
  };
}
