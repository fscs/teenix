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
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud28;

    hostName = opts.hostname;
    phpExtraExtensions = all: [ all.pdlib all.bz2 all.smbclient ];

    database.createLocally = true;

    settings.trusted_domains = [ "192.168.100.11" opts.hostname ];
    config = {
      adminpassFile = host-config.sops.secrets.nextcloud_pass.path;
      dbtype = "pgsql";
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
