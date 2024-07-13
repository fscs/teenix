{ lib
, config
, ...
}: {
  options.teenix.services.nextcloud = {
    enable = lib.mkEnableOption "setup nextcloud";
    hostname = lib.mkOption {
      type = lib.types.str;
      description = "hostname";
    };
    secretsFile = lib.mkOption {
      type = lib.types.path;
      description = "path to the sops secret file for the adminPass";
    };

  };
  config =
    let
      opts = config.teenix.services.nextcloud;
    in
    lib.mkIf opts.enable {
      sops.secrets.nextcloud_pass = {
        sopsFile = opts.secretsFile;
        format = "binary";
        mode = "444";
      };
      containers.nextcloud = {
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.100.10";
        localAddress = "192.168.100.11";
        bindMounts =
          {
            "secret" =
              {
                hostPath = config.sops.secrets.nextcloud_pass.path;
                mountPoint = config.sops.secrets.nextcloud_pass.path;
              };
          };

        config = { pkgs, lib, ... }: {
          services.nextcloud = {
            enable = true;
            package = pkgs.nextcloud29;
            hostName = opts.hostname;
            phpExtraExtensions = all: [ all.pdlib all.bz2 all.smbclient ];

            database.createLocally = true;

            settings.trusted_domains = [ "192.168.100.11" ];
            config = {
              adminpassFile = config.sops.secrets.nextcloud_pass.path;
              dbtype = "pgsql";
            };

            phpOptions = {
              "opcache.jit" = "1255";
              "opcache.revalidate_freq" = "60";
              "opcache.interned_strings_buffer" = "16";
              "opcache.jit_buffer_size" = "128M";
            };

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

          system.stateVersion = "23.11";

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
        };
      };
    };
}
