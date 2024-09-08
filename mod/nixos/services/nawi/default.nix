{ lib
, config
, ...
}: {
  options.teenix.services.nawi =
    let
      t = lib.types;
    in
    {
      enable = lib.mkEnableOption "setup nawi";
      hostname = lib.mkOption {
        type = t.str;
      };
      envFile = lib.mkOption {
        type = t.path;
      };
      mariaEnvFile = lib.mkOption {
        type = t.path;
      };
    };

  config =
    let
      opts = config.teenix.services.nawi;
    in
    lib.mkIf opts.enable {
      sops.secrets.nawi_mariadb = {
        sopsFile = opts.mariaEnvFile;
        format = "binary";
        mode = "444";
      };

      sops.secrets.nawi = {
        sopsFile = opts.envFile;
        format = "binary";
        mode = "444";
      };

      nix-tun.storage.persist.subvolumes."nawi".directories = {
        "/mysql" = {
          owner = "1000"; #TODO: Set the correct owner and mode
          mode = "0777";
        };
        "/wp" = {
          owner = "1000"; #TODO: Set the correct owner and mode
          mode = "0777";
        };
      };

      teenix.services.traefik.services."nawi" = {
        router.rule = "Host(`${opts.hostname}`) || Host(`www.${opts.hostname}`)";
        #TODO: Set the adderees dynamically maybe traefix docker impl
        servers = [ "http://172.17.0.7:80" ];
      };

      virtualisation.docker.rootless = {
        enable = true;
        setSocketVariable = true;
      };

      virtualisation.oci-containers = {
        backend = "docker";
        containers = {
          nawi = {
            image = "wordpress";
            dependsOn = [ "mariadb-nawi" ];
            environmentFiles = [ config.sops.secrets.nawi.path ];
            volumes = [
              "${config.nix-tun.storage.persist.path}/nawi/wp:/var/www/html"
            ];
            environment = {
              WORDPRESS_DB_HOST = "172.17.0.6";
              WORDPRESS_DB_USER = "nawi";
              WORDPRESS_DB_NAME = "nawidb";
            };
          };
          mariadb-nawi = {
            image = "mariadb";
            environmentFiles = [ config.sops.secrets.nawi_mariadb.path ];
            volumes = [
              "${config.nix-tun.storage.persist.path}/nawi/mysql:/var/lib/mysql"
            ];
            environment = {
              MYSQL_DATABASE = "nawidb";
              MYSQL_USER = "nawi";
            };
          };
        };
      };
    };
}

