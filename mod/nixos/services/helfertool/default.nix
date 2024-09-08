{ lib
, config
, ...
}: {
  options.teenix.services.helfertool =
    let
      t = lib.types;
    in
    {
      enable = lib.mkEnableOption "setup helfertool";
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
      opts = config.teenix.services.helfertootl;
    in
    lib.mkIf opts.enable {
      sops.secrets.passbolt = {
        sopsFile = opts.envFile;
        format = "binary";
        mode = "444";
      };

      sops.secrets.passbolt_mariadb = {
        sopsFile = opts.mariaEnvFile;
        format = "binary";
        mode = "444";
      };

      nix-tun.storage.persist.subvolumes."passbolt".directories = {
        "/mariadb" = {
          owner = "1000"; #TODO: Set the correct owner and mode
          mode = "0777";
        };
        "/env" = {
          owner = "1000"; #TODO: Set the correct owner and mode
          mode = "0777";
        };
      };

      teenix.services.traefik.services."passbolt" = {
        router.rule = "Host(`${opts.hostname}`)";
        #TODO: Set the adderees dynamically maybe traefix docker impl
        servers = [ "http://172.17.0.3:80" ];
      };

      virtualisation.docker.rootless = {
        enable = true;
        setSocketVariable = true;
      };

      virtualisation.oci-containers = {
        backend = "docker";
        containers = {
          passbolt = {
            image = "passbolt/passbolt";
            dependsOn = [ "mariadb" ];
            environmentFiles = [ config.sops.secrets.passbolt.path ];
            volumes = [
              "${config.nix-tun.storage.persist.path}/passbolt/mysql:/var/lib/mysql"
            ];
            environment = {
              DATASOURCES_DEFAULT_HOST = "mariadb";
              DATASOURCES_DEFAULT_USERNAME = "passbolt";
              DATASOURCES_DEFAULT_DATABASE = "passbolt";
              DATASOURCES_DEFAULT_PORT = "3306";
              DATASOURCES_QUOTE_IDENTIFIER = "true";
              APP_FULL_BASE_URL = "https://passbolt.fscs-hhu.de";
              EMAIL_DEFAULT_FROM = "fscs@hhu.de";
              EMAIL_TRANSPORT_DEFAULT_TLS = "true";
              PASSBOLT_KEY_EMAIL = "fscs@hhu.de";
            };
          };
          mariadb = {
            image = "mariadb";
            environmentFiles = [ config.sops.secrets.passbolt_mariadb.path ];
            volumes = [
              "${config.nix-tun.storage.persist.path}/passbolt/gpg:/etc/passbolt/gpg"
              "${config.nix-tun.storage.persist.path}/passbolt/jwtc:/etc/passbolt/jwtc"
            ];
            environment = {
              MYSQL_DATABASE = "passbolt";
              MYSQL_USER = "passbolt";
            };
          };
        };
      };
    };
}
