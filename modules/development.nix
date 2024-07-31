{ outputs, pkgs, ... }:
let
  inherit (outputs) username;
in
{
  home-manager.users.${username} = {
    home.packages = with pkgs; with nodePackages_latest; with gnome; with libsForQt5; [
      # LANGS
      # jdk # has compatibility issues
      R
      bun
      dart
      elixir
      eslint
      gcc
      gjs
      go
      mono5 # C#
      nodejs
      php
      rustup
      typescript
      nuget # C#
      boost

      # DEVELOPMENT
      # k3s
      awscli
      azure-cli
      direnv
      docker
      docker-compose
      kubernetes
      maven
      minikube
      ollama
      sqlcl
      sqldeveloper
      sqlite
      terraform
      vault # HashiCorp Vault 
      vsh # HashiCorp Vault Shell
      asio # c++
      cmake

      # LIBRARIES
      stdenv.cc.cc.lib
    ];
  };
}
