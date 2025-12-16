{
  pkgs,
  unstable,
  hostname,
  ...
}:
with pkgs;
[
  # LANGUAGES
  # jdk # has compatibility issues
  # R
  # bun
  # dart
  # elixir
  # eslint
  gcc
  go
  # mono5 # C#
  # php
  rustup # rust version manager
  # nuget # C#
  # boost
  ghc
  haskell-language-server
  nil # nix

  # NODE.JS DEVELOPMENT TOOLS
  # fzf
  unstable.nodejs
  unstable.typescript
  unstable.eslint
  # unstable.nodePackages.live-server # removed because it was unmaintained
  unstable.nodePackages.nodemon
  unstable.nodePackages.prettier
  # unstable.nodePackages.npm # nodejs already includes this?
  unstable.nodePackages.neovim
  # unstable.vimPlugins.nvim-treesitter.withPlugins
  # unstable.neovimUtils.makeNeovim

  # PHP
  # php82
  # php82Packages.composer
  # php82Packages.php-cs-fixer
  # php82Extensions.xdebug
  # php82Packages.deployer
  # phpunit

  # PYTHON PACKAGES
  # black
  (python311.withPackages (
    p:
    if hostname == "nixos" then
      [
        p.material-color-utilities
        p.pywayland
      ]
    else
      [ ]
  ))
  python311Packages.pip
  virtualenv
  ## fast python package manager written in rust
  ## replaces: pip, pip-tools, pipx, poetry, pyenv, twine, virtualenv, and more
  uv

  # DEVELOPMENT
  # awscli
  # azure-cli
  # direnv
  maven
  # ollama
  # sqlcl
  # sqldeveloper # download here https://www.oracle.com/java/technologies/javase/javase8u211-later-archive-downloads.html#license-lightbox
  sqlite
  terraform
  # vault # HashiCorp Vault
  # vsh # HashiCorp Vault Shell
  # asio # c++
  tree-sitter

  # CLOUD/DEVOPS
  awscli2 # marked broken Mar 22
  # flyctl
  # google-cloud-sdk
  # gopls
  # ngrok
  # ssm-session-manager-plugin
  terraform
  # terraform-ls
  # tflint

  nixfmt-rfc-style
  # nixpkgs-fmt
  # nixfmt-classic
]
