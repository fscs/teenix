{ config, pkgs, ... }:
{
  users.groups.pg-cluster = { };
  services.etcd = {
    enable = true;
    name = "etcd-node-node2";
    initialCluster = [
      "etcd-node-node1=http://134.99.147.42:2380"
      "etcd-node-node2=http://134.99.147.43:2380"
      "etcd-node-node3=http://134.99.147.41:2380"
    ];
    advertiseClientUrls = [ "http://134.99.147.43:2379" ];
    listenClientUrls = [ "http://0.0.0.0:2379" ];
    listenPeerUrls = [ "http://134.99.147.43:2380" ];
    initialAdvertisePeerUrls = [ "http://134.99.147.43:2380" ];
    initialClusterToken = "etcd-cluster-1";
    initialClusterState = "existing"; # ACHTUNG: Nur beim ersten Bootstrap auf allen drei Nodes "new" setzen
  };

  services.patroni = {
    enable = true;
    name = "node2";
    nodeIp = "134.99.147.43";
    group = "pg-cluster";
    scope = "pg-cluster";
    restApiPort = 8008;
    postgresqlPort = 5432;
    postgresqlPackage = pkgs.postgresql_16;
    postgresqlDataDir = "/var/lib/postgresql/16/data";
    otherNodesIps = [ "134.99.147.42" ];
    softwareWatchdog = false;

    settings = {
      etcd3 = {
        hosts = "134.99.147.42:2379,134.99.147.43:2379";
      };
      postgresql = {
        parameters = {
          wal_level = "replica";
          max_wal_senders = 10;
          wal_keep_size = "1024MB";
          max_replication_slots = 10;
          hot_standby = "on";
          archive_mode = "off";
        };
        authentication = {
          replication = {
            username = "replicator";
            password = "ReplicationPassword123";
          };
          superuser = {
            username = "postgres";
            password = "SuperSecretPassword123"; # Hier Passwort anpassen
          };
        };
      };
    };
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
