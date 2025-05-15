{ config, pkgs, ... }:
{
  sops.secrets.patroni-postgres-password = {
    sopsFile = ../secrets/patroni.yml;
    key = "postgres-password";
    owner = "patroni";
  };

  sops.secrets.patroni-replicator-password = {
    sopsFile = ../secrets/patroni.yml;
    key = "replicator-password";
    owner = "patroni";
  };

  sops.secrets.patroni-rewind-password = {
    sopsFile = ../secrets/patroni.yml;
    key = "rewind-password";
    owner = "patroni";
  };

  systemd.tmpfiles.rules = [
    "d /run/postgresql 0755 patroni pg-cluster -"
  ];

  teenix.persist.subvolumes.postgresql.directories = {
    etcd = {
      owner = "etcd";
      mode = "0700";
    };
    db = {
      owner = "patroni";
      mode = "0700";
    };
    patroni = {
      owner = "patroni";
      mode = "0700";
    };
  };

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
    initialClusterState = "new";
    dataDir = "/persist/postgresql/etcd";
  };

  services.patroni = {
    enable = true;
    dataDir = "/persist/postgresql/patroni";
    name = "node2";
    nodeIp = "134.99.147.43";
    group = "pg-cluster";
    scope = "pg-cluster";
    restApiPort = 8008;
    postgresqlPort = 5432;
    postgresqlPackage = pkgs.postgresql_16;
    postgresqlDataDir = "/persist/postgresql/db";
    otherNodesIps = [ "134.99.147.42" ];
    softwareWatchdog = false;
    environmentFiles = {
      PATRONI_REPLICATION_PASSWORD = config.sops.secrets.patroni-replicator-password.path;
      PATRONI_SUPERUSER_PASSWORD = config.sops.secrets.patroni-postgres-password.path;
    };
    settings = {
      etcd3 = {
        hosts = "134.99.147.42:2379,134.99.147.43:2379";
      };
      postgresql = {
        data_dir = "/persist/postgresql/db";
        config_dir = "/persist/postgresql/db";
        parameters = {
          wal_level = "replica";
          max_wal_senders = 10;
          wal_keep_size = "1024MB";
          max_replication_slots = 10;
          hot_standby = "on";
          archive_mode = "off";
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
