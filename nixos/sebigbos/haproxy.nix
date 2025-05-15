{ config, pkgs, ... }:

{
  teenix.persist.subvolumes.postgresql.directories = {
    etcd = {
      owner = "etcd";
      mode = "0700";
    };
  };

  services.etcd = {
    enable = true;
    name = "etcd-node-node3";
    initialCluster = [
      "etcd-node-node1=http://134.99.147.42:2380"
      "etcd-node-node2=http://134.99.147.43:2380"
      "etcd-node-node3=http://134.99.147.41:2380"
    ];
    advertiseClientUrls = [ "http://134.99.147.41:2379" ];
    listenClientUrls = [ "http://0.0.0.0:2379" ];
    listenPeerUrls = [ "http://134.99.147.41:2380" ];
    initialAdvertisePeerUrls = [ "http://134.99.147.41:2380" ];
    initialClusterToken = "etcd-cluster-1";
    initialClusterState = "new";
    dataDir = "/persist/postgresql/etcd";
  };

  services.haproxy.enable = true;

  services.haproxy.config = ''
    global
       log /dev/log local0
       log /dev/log local1 notice
       stats timeout 30s
       user haproxy
       group haproxy
       daemon

     defaults
       log     global
       mode    tcp
       option  tcplog
       option  dontlognull
       timeout connect 5s
       timeout client  30s
       timeout server  30s

     frontend pgsql_frontend
       bind *:5432
       default_backend pgsql_write_pool

     backend pgsql_write_pool
       option httpchk GET /leader
       http-check expect status 200
       # Node1 is active by default
       server node1 134.99.147.42:5432 check port 8008 inter 2s fall 2 rise 1
       server node2 134.99.147.43:5432 check port 8008 inter 2s fall 2 rise 1 backup
  '';
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      5432
      2379
      2380
    ]; # HAProxy listening port
  };
}
