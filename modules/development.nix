{ pkgs, ... }:
let
  username = "trey";
in
{
  # TODO: use foldl' or similar to map users to same package list
  home-manager.users.${username} = {
    home.packages = with pkgs; with nodePackages_latest; with gnome; with libsForQt5; [
      openvpn

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
      # sqldeveloper # download here https://www.oracle.com/java/technologies/javase/javase8u211-later-archive-downloads.html#license-lightbox
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

  services = {
    mysql = {
      enable = true;
      package = pkgs.mariadb;
      #configFile = pkgs.writeText "mysql.conf" ''
      ## [mariadb]
      ## unix_socket=OFF
      ## unix_socket=OFF
      ## [client]
      ## user=pdns
      ##  password=teleport
      #[mysql]
      ## unix_socket=OFF
      #database = pdns
      #port = 3306
      #socket = /run/mysqld/mysqld.sock
      #'';
      #initialDatabases = [
      #  {
      #  name = "pdns";
      #  schema = "${pkgs.powerdns}/share/pdns-mysql/schema.mysql.sql";
      #  }
      #];
      #services.mysql.replication.role = "master";
      #services.mysql = {
      #replication.role = "master";
      #replication.slaveHost = "127.0.0.1";
      #replication.masterUser = "pdns";
      #replication.masterPassword = "teleport";
      #};
      #services.mysql.ensureDatabases = ["pdns"];
      #services.mysql.ensureUsers = [
      #  {
      #    name = "pdns";
      #    ensurePermissions = {
      #      "pdns" = "ALL PRIVILEGES";  
      #    };
      #  }  
      #]; 
    };
    postgresql = {
      enable = true;
      ensureDatabases = [ "mydatabase" ];
      authentication = pkgs.lib.mkOverride 10 ''
        #type database  DBuser  auth-method
        local all       all     trust
      '';
    };
    # nfs.server = {
    #   enable = true;
    #   exports = ''
    #     /nix  192.168.0.114(rw,nohide,insecure,no_subtree_check)
    #   '';
    #     # /export         192.168.1.10(rw,fsid=0,no_subtree_check) 192.168.1.15(rw,fsid=0,no_subtree_check)
    #     # /export/kotomi  192.168.1.10(rw,nohide,insecure,no_subtree_check) 192.168.1.15(rw,nohide,insecure,no_subtree_check)
    #     # /export/mafuyu  192.168.1.10(rw,nohide,insecure,no_subtree_check) 192.168.1.15(rw,nohide,insecure,no_subtree_check)
    #     # /export/sen     192.168.1.10(rw,nohide,insecure,no_subtree_check) 192.168.1.15(rw,nohide,insecure,no_subtree_check)
    #     # /export/tomoyo  192.168.1.10(rw,nohide,insecure,no_subtree_check) 192.168.1.15(rw,nohide,insecure,no_subtree_check)
    # }
  };

}
