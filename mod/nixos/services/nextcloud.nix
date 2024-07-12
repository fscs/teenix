{ lib
, config
, ...
}: {
  options.teenix.services.nextcloud = {
    enable = lib.mkEnableOption "setup nextcloud";
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
      };
      networking.nat = {
        enable = true;
        internalInterfaces = [ "ve-+" ];
        externalInterface = "eno1";
        # Lazy IPv6 connectivity for the container
        enableIPv6 = true;
      };
      containers.nextcloud = {
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.100.10";
        localAddress = "192.168.100.11";
        config = { pkgs, lib, ... }: {

          services.nextcloud = {
            enable = true;
            package = pkgs.nextcloud29;
            hostName = "localhost";

            phpExtraExtensions = all: [ all.pdlib all.bz2 all.smbclient ];
            config = {
              adminpassFile = config.sops.secrets.nextcloud_pass.path;
              dbtype = "pgsql";
              dbhost = "/var/run/postgresql";
              dbuser = "postgres";
              dbname = "nextcloud";
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

            services.postgresql = {
              enable = true;
              ensureDatabases = [ "nextcloud" ];
              package = pkgs.postgresql_16_jit;
              authentication = pkgs.lib.mkOverride 10 ''
                #type database  DBuser  auth-method
                local all       all     trust
              '';
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
    };
}
