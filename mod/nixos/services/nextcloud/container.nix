{
  lib,
  config,
  host-config,
  pkgs,
  ...
}:
let
  cfg = host-config.teenix.services.nextcloud;
in
{
  users = {
    # needed to access the netapp lols
    users.nextcloud.uid = 33;
    groups.nextcloud.gid = 33;
    users.nginx.group = lib.mkForce "nextcloud";
  };

  environment.systemPackages = [
    config.services.nextcloud.occ
  ];

  services.mysql.settings = {
    mysqld = {
      innodb_buffer_pool_size = "3G";
      innodb_io_capacity = 4000;
    };
  };

  services.prometheus.exporters.nextcloud = {
    enable = true;
    url = "https://${cfg.hostname}";
    tokenFile = host-config.sops.secrets.nextcloud-serverinfo-token.path;
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud31;

    https = true;
    hostName = cfg.hostname;

    notify_push = {
      enable = true;
      nextcloudUrl = "https://${cfg.hostname}";
    };

    phpExtraExtensions =
      all: with all; [
        pdlib
        bz2
        smbclient
      ];

    database.createLocally = true;

    settings = {
      trusted_domains = [
        "134.99.154.48"
        host-config.containers.nextcloud.localAddress
        host-config.containers.nextcloud.hostAddress
        cfg.hostname
        config.networking.hostName
      ];
      trusted_proxies = [
        "${host-config.containers.nextcloud.hostAddress}"
        "${host-config.containers.nextcloud.localAddress}"
        "::1"
      ];
    };

    config = {
      adminpassFile = host-config.sops.secrets.nextcloud-admin-pass.path;
      dbtype = "mysql";
    };

    phpOptions = {
      "opcache.jit" = "1255";
      "opcache.revalidate_freq" = "60";
      "opcache.interned_strings_buffer" = "16";
      "opcache.jit_buffer_size" = "128M";
      "apc.shm_size" = "1G";
    };

    extraApps = lib.attrsets.getAttrs cfg.extraApps config.services.nextcloud.package.packages.apps;
    extraAppsEnable = true;

    configureRedis = true;
    caching.apcu = true;
    poolSettings = {
      pm = "dynamic";
      "pm.max_children" = "201";
      "pm.max_requests" = "500";
      "pm.max_spare_servers" = "150";
      "pm.min_spare_servers" = "50";
      "pm.start_servers" = "50";
    };
  };

  services.nginx.virtualHosts.${cfg.hostname}.extraConfig = lib.mkAfter ''
    gzip_types text/javascript;
  '';

  system.stateVersion = "23.11";
}
