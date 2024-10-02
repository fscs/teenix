{ lib
, config
, host-config
, pkgs
, pkgs-master
, ...
}:
let
  opts = host-config.teenix.services.nextcloud;
in
{
  users.users.nextcloud.uid = 33;
  users.groups.nextcloud.gid = 33;

  programs.appimage.enable = true;
  programs.appimage.binfmt = true;

  services.nextcloud = {
    enable = true;
    package = pkgs-master.nextcloud30;
    notify_push = {
      enable = true;
      bendDomainToLocalhost = true;
      # The module checks in a weird way if we use a unix socket
      dbhost = "/run/mysqld/mysqld.sock";
      dbuser = "nextcloud@localhost:";
    };

    https = true;

    hostName = opts.hostname;
    phpExtraExtensions = all: [ all.pdlib all.bz2 all.smbclient ];

    database.createLocally = true;

    settings.trusted_domains = [ "134.99.154.48" "192.168.100.11" "192,168.100.10" opts.hostname config.networking.hostName ];
    settings.trusted_proxies = [ "192.168.100.10" "192.168.100.11" ];
    config = {
      adminpassFile = host-config.sops.secrets.nextcloud_pass.path;
      dbtype = "mysql";
    };

    phpOptions = {
      "opcache.jit" = "1255";
      "opcache.revalidate_freq" = "60";
      "opcache.interned_strings_buffer" = "16";
      "opcache.jit_buffer_size" = "128M";
    };

    extraApps = lib.attrsets.getAttrs opts.extraApps config.services.nextcloud.package.packages.apps;
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

  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 80 ];
    };
    # Use systemd-resolved inside the container
    # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
    useHostResolvConf = lib.mkForce false;
  };

  services.resolved.enable = true;

  system.stateVersion = "23.11";
}
