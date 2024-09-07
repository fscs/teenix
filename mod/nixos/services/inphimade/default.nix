{ lib
, config
, ...
}: {
  options.teenix.services.inphimade =
    let
      t = lib.types;
    in
    {
      enable = lib.mkEnableOption "setup inphimade";
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
      opts = config.teenix.services.inphimade;
    in
    lib.mkIf opts.enable {
      sops.secrets.inphimade_mariadb = {
        sopsFile = opts.mariaEnvFile;
        format = "binary";
        mode = "444";
      };

      nix-tun.storage.persist.subvolumes."inphimade".directories = {
        "/mysql" = {
          owner = "1000"; #TODO: Set the correct owner and mode
          mode = "0777";
        };
        "/wp" = {
          owner = "1000"; #TODO: Set the correct owner and mode
          mode = "0777";
        };
      };

      teenix.services.traefik.services."inphimade" = {
        router.rule = "Host(`${opts.hostname}`)";
        #TODO: Set the adderees dynamically maybe traefix docker impl
        servers = [ "http://172.17.0.5:80" ];
      };

      virtualisation.docker.rootless = {
        enable = true;
        setSocketVariable = true;
      };

      virtualisation.oci-containers = {
        backend = "docker";
        containers = {
          inphimade = {
            image = "wordpress";
            dependsOn = [ "mariadb-inphimade" ];
            environmentFiles = [ config.sops.secrets.passbolt.path ];
            volumes = [
              "${config.nix-tun.storage.persist.path}/inphimade/wp:/var/www/html"
            ];
            environment = {
              WORDPRESS_DB_HOST = "127.17.0.4";
              WORDPRESS_DB_USER = "inphima";
              WORDPRESS_DB_NAME = "inphimadb";
            };
          };
          mariadb-inphimade = {
            image = "mariadb";
            environmentFiles = [ config.sops.secrets.passbolt_mariadb.path ];
            volumes = [
              "${config.nix-tun.storage.persist.path}/inphimade/mysql:/var/lib/mysql"
            ];
            environment = {
              MYSQL_DATABASE = "inphimadb";
              MYSQL_USER = "inphima";
            };
          };
        };
      };
    };
}
