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

  environment.systemPackages = [
    pkgs.docker
  ];

  services.nextcloud = {
    enable = true;
    package = pkgs-master.nextcloud30;
    notify_push = {
      enable = false;
    };

    https = true;

    hostName = opts.hostname;
    phpExtraExtensions = all: [
      all.pdlib
      all.bz2
      all.smbclient
    ];

    database.createLocally = true;

    settings.trusted_domains = [
      "134.99.154.48"
      "192.168.100.11"
      "192.168.100.10"
      opts.hostname
      config.networking.hostName
    ];
    settings.trusted_proxies = [
      "192.168.100.10"
      "::1"
    ];
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
  users.users.nginx.group = "nextcloud";
  services.nginx.virtualHosts."nextcloud.inphima.de".extraConfig = lib.mkForce ''
    index index.php index.html /index.php$request_uri;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Robots-Tag "noindex, nofollow" always;
    add_header X-Download-Options noopen always;
    add_header X-Permitted-Cross-Domain-Policies none always;
    add_header X-Frame-Options sameorigin always;
    add_header X-Content-Type-Options nosniff;
    add_header Referrer-Policy no-referrer always;
    add_header Strict-Transport-Security "max-age=${toString config.services.nextcloud.nginx.hstsMaxAge}; includeSubDomains" always;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    client_max_body_size ${config.services.nextcloud.maxUploadSize};
    fastcgi_buffers 64 4K;
    fastcgi_hide_header X-Powered-By;
    gzip on;
    gzip_vary on;
    gzip_comp_level 4;
    gzip_min_length 256;
    gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
    gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;
  '';

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
