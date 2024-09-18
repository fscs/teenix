{ lib
, config
, host-config
, pkgs
, ...
}:
let
  opts = host-config.teenix.services.nextcloud;
in
{
  users.users.nextcloud.uid = 33;
  users.groups.nextcloud.gid = 33;

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud29;
    notify_push = {
      enable = true;
      # The module checks in a weird way if we use a unix socket
      dbhost = "/run/mysqld/mysqld.sock";
      dbuser = "nextcloud@localhost:";
    };



    https = true;

    hostName = opts.hostname;
    phpExtraExtensions = all: [ all.pdlib all.bz2 all.smbclient ];

    database.createLocally = true;

    settings.trusted_domains = [ "134.99.154.48" "192.168.100.11" "192,168.100.10" opts.hostname config.networking.hostName ];
    settings.trusted_proxies = [ "192.168.100.10" ];
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

  services.nginx.virtualHosts.${opts.hostname} = {
    locations = {
      "~ ^\/nextcloud\/(?:index|remote|public|cron|core\/ajax\/update|status|ocs\/v[12]|updater\/.+|oc[ms]-provider\/.+|.+\/richdocumentscode\/proxy)\.php(?:$|\/)" = {
        extraConfig = ''
          fastcgi_split_path_info ^(.+?\.php)(\/.*|)$;
          set $path_info $fastcgi_path_info;
          try_files $fastcgi_script_name =404;
          include fastcgi_params;
          fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
          fastcgi_param PATH_INFO $path_info;
          fastcgi_param HTTPS on;
          # Avoid sending the security headers twice
          fastcgi_param modHeadersAvailable true;
          # Enable pretty urls
          fastcgi_param front_controller_active true;
          fastcgi_pass php-handler;
          fastcgi_intercept_errors on;
          fastcgi_request_buffering off;
        '';
      };
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
