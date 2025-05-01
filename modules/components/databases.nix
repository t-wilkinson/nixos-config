{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.mysql
    pkgs.postgesql
  ];

  services.mysql = {
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
}
