{ pkgs, unstable, ... }:
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
  # gjs
  go
  # mono5 # C#
  # php
  rustup # rust version manager
  # nuget # C#
  # boost
  ghc
  haskell-language-server

  # NODE.JS DEVELOPMENT TOOLS
  # fzf
  unstable.nodejs
  unstable.typescript
  unstable.nodePackages.live-server
  unstable.nodePackages.nodemon
  unstable.nodePackages.prettier
  unstable.nodePackages.npm

  # openvpn
  # chromedriver

  # DEVELOPMENT
  # k3s
  # awscli
  # azure-cli
  # direnv
  # kubernetes
  maven
  minikube
  # ollama
  # sqlcl
  # sqldeveloper # download here https://www.oracle.com/java/technologies/javase/javase8u211-later-archive-downloads.html#license-lightbox
  sqlite
  terraform
  vault # HashiCorp Vault
  vsh # HashiCorp Vault Shell
  # asio # c++

  # PHP
  # php82
  # php82Packages.composer
  # php82Packages.php-cs-fixer
  # php82Extensions.xdebug
  # php82Packages.deployer
  # phpunit

  # PYTHON PACKAGES
  # black
  python3
  python3Packages.pip
  virtualenv

  # CLOUD/DEVOPS
  # docker
  # docker-compose
  # awscli2 - marked broken Mar 22
  # flyctl
  # google-cloud-sdk
  # go
  # gopls
  # ngrok
  # ssm-session-manager-plugin
  terraform
  # terraform-ls
  # tflint

  nixfmt-rfc-style
]
