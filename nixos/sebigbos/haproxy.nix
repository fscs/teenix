{ config, pkgs, ... }:

{
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
    initialClusterState = "existing"; # ACHTUNG: Nur beim ersten Bootstrap auf allen drei Nodes "new" setzen
    dataDir = "/var/lib/etcd";
  };

  services.haproxy.enable = true;

  services.haproxy.config = ''
    global
      log stdout format raw local0
      maxconn 2000
      tune.ssl.default-dh-param 2048

    defaults
      log     global
      mode    tcp
      option  tcplog
      timeout connect 10s
      timeout client  1m
      timeout server  1m

    frontend pgsql_frontend
      bind *:5432
      default_backend pgsql_back

    backend pgsql_back
      option tcp-check
      tcp-check connect
      tcp-check send "GET / HTTP/1.0\r\n\r\n"
      http-check expect string "\"role\": \"primary\""
      server node1 134.99.147.42:5432 check port 8008 inter 2000 rise 2 fall 3
      server node2 134.99.147.43:5432 check port 8008 inter 2000 rise 2 fall 3 backup
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
