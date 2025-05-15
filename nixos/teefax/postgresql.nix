{
  pkgs,
  lib,
  config,
  ...
}:
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

  services.patroni = {
    enable = true;
    dataDir = "/persist/postgresql/patroni";
    name = "node1";
    nodeIp = "134.99.147.42";
    group = "pg-cluster";
    scope = "pg-cluster";
    postgresqlPort = 5432;
    postgresqlDataDir = "/persist/postgresql/db";
    postgresqlPackage = pkgs.postgresql_16;
    restApiPort = 8008;
    otherNodesIps = [ "134.99.147.43" ];
    softwareWatchdog = false;
    environmentFiles = {
      PATRONI_REPLICATION_PASSWORD = config.sops.secrets.patroni-replicator-password.path;
      PATRONI_SUPERUSER_PASSWORD = config.sops.secrets.patroni-postgres-password.path;
      PATRONI_REWIND_PASSWORD = config.sops.secrets.patroni-rewind-password.path;
    };
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
          "host replication patroni 127.0.0.1/32 md5"
          "host replication patroni 134.99.147.0/24 md5"
          "host all all 0.0.0.0/0 md5"
        ];
      };

      postgresql = {
        data_dir = "/persist/postgresql/db";
        config_dir = "/persist/postgresql/db";
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
    initialClusterState = "new";
    dataDir = "/persist/postgresql/etcd";
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
