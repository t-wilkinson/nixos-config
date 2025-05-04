{ pkgs, pkgs-unstable, ... }:
# let
#   mynodePackages23 = pkgs.nodePackages.override {
#     nodejs = pkgs.nodejs-23_x;
#   };
# in 
with pkgs; [
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
  rustup
  # typescript
  # nuget # C#
  # boost
  pkgs-unstable.nodejs
  # mypkgs.npm
  pkgs-unstable.nodePackages.npm

  # openvpn
  # chromedriver

  # DEVELOPMENT
  # k3s
  # awscli
  # azure-cli
  # direnv
  # kubernetes
  # maven
  # minikube
  # ollama
  # sqlcl
  # sqldeveloper # download here https://www.oracle.com/java/technologies/javase/javase8u211-later-archive-downloads.html#license-lightbox
  # sqlite
  # terraform
  # vault # HashiCorp Vault
  # vsh # HashiCorp Vault Shell
  # asio # c++

  # PHP
  # php82
  # php82Packages.composer
  # php82Packages.php-cs-fixer
  # php82Extensions.xdebug
  # php82Packages.deployer
  # phpunit

  # NODE.JS DEVELOPMENT TOOLS
  # fzf
  # nodePackages.live-server
  # nodePackages.nodemon
  # nodePackages.prettier
  # nodePackages.npm

  # PYTHON PACKAGES
  # black
  python3
  python3Packages.pip
  # virtualenv

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
  # terraform
  # terraform-ls
  # tflint
]
 
