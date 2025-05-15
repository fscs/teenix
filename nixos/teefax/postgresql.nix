{
  pkgs,
  lib,
  config,
  ...
}:
{
  users.groups.pg-cluster = { };
  services.patroni = {
    enable = true;
    name = "node1";
    nodeIp = "134.99.147.42";
    group = "pg-cluster";
    scope = "pg-cluster";
    postgresqlPort = 5432;
    postgresqlDataDir = "/var/lib/postgresql/16/data";
    postgresqlPackage = pkgs.postgresql_16;
    restApiPort = 8008;
    otherNodesIps = [ "134.99.147.43" ];
    softwareWatchdog = false;
    settings = {
      etcd3 = {
        hosts = "134.99.147.42:2379,134.99.147.43:2379";
      };
      bootstrap = {
        dcs = {
          ttl = 30;
          loop_wait = 10;
          retry_timeout = 10;
          maximum_lag_on_failover = 1048576;
          postgresql = {
            use_pg_rewind = true;
            use_slots = true;
          };
        };
        initdb = {
          encoding = "UTF8";
          locale = "en_US.UTF-8";
        };
        pg_hba = [
          "local all all trust"
          "host replication replicator 127.0.0.1/32 md5"
          "host replication replicator 134.99.147.0/24 md5"
          "host all all 0.0.0.0/0 md5"
        ];
      };

      postgresql = {
        data_dir = "/var/lib/postgresql/16/data";
        config_dir = "/var/lib/postgresql/16/data";

        authentication = {
          superuser = {
            username = "postgres";
            password = "SuperSecretPassword123"; # Hier Passwort anpassen
          };
          replication = {
            username = "replicator";
            password = "ReplicationPassword123"; # Hier Passwort anpassen
          };
          rewind = {
            username = "rewinduser";
            password = "RewindPassword123";
          };
        };
      };
    };
  };

  services.etcd = {
    enable = true;
    name = "etcd-node-node1";
    initialCluster = [
      "etcd-node-node1=http://134.99.147.42:2380"
      "etcd-node-node2=http://134.99.147.43:2380"
      "etcd-node-node3=http://134.99.147.41:2380"
    ];
    advertiseClientUrls = [ "http://134.99.147.42:2379" ];
    listenClientUrls = [ "http://0.0.0.0:2379" ];
    listenPeerUrls = [ "http://134.99.147.42:2380" ];
    initialAdvertisePeerUrls = [ "http://134.99.147.42:2380" ];
    initialClusterToken = "etcd-cluster-1";
    initialClusterState = "existing"; # ACHTUNG: Nur beim ersten Bootstrap auf allen drei Nodes "new" setzen
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      5432
      8008
      2379
      2380
    ]; # PostgreSQL, Patroni REST API, etcd ports
  };
}
