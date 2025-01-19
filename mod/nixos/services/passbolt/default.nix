{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.teenix.services.passbolt =
    {
      enable = lib.mkEnableOption "setup passbolt";
      hostname = lib.teenix.mkHostnameOption;
      secretsFile = lib.teenix.mkSecretsFileOption "passbolt";
      mariaEnvFile = lib.mkOption {
        type = lib.types.path;
      };
    };

  config =
    let
      opts = config.teenix.services.passbolt;
    in
    lib.mkIf opts.enable {
      sops.secrets.passbolt = {
        sopsFile = opts.secretsFile;
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
          owner = "1000"; # TODO: Set the correct owner and mode
          mode = "0777";
        };
        "/env" = {
          owner = "1000"; # TODO: Set the correct owner and mode
          mode = "0777";
        };
        "/gpg" = {
          owner = "1000"; # TODO: Set the correct owner and mode
          mode = "0777";
        };
        "/jwtc" = {
          owner = "1000"; # TODO: Set the correct owner and mode
          mode = "0777";
        };
      };

      # Runtime
      virtualisation.docker = {
        enable = true;
        autoPrune.enable = true;
      };
      virtualisation.oci-containers.backend = "docker";

      # Containers
      virtualisation.oci-containers.containers."passbolt-mariadb" = {
        image = "mariadb:latest";
        environment = {
          "MYSQL_DATABASE" = "passbolt";
          "MYSQL_USER" = "passbolt";
        };
        environmentFiles = [ config.sops.secrets.passbolt_mariadb.path ];
        volumes = [
          "${config.nix-tun.storage.persist.path}/passbolt/mariadb:/var/lib/mysql"
        ];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=mariadb"
          "--network=passbolt_default"
        ];
      };
      systemd.services."docker-passbolt-mariadb" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-passbolt_default.service"
          "docker-volume-passbolt_database_volume.service"
        ];
        requires = [
          "docker-network-passbolt_default.service"
          "docker-volume-passbolt_database_volume.service"
        ];
        partOf = [
          "docker-compose-passbolt-root.target"
        ];
        wantedBy = [
          "docker-compose-passbolt-root.target"
        ];
      };
      virtualisation.oci-containers.containers."passbolt-passbolt" = {
        image = "passbolt/passbolt:latest-ce-non-root";
        environment = {
          "APP_FULL_BASE_URL" = "https://passbolt.hhu-fscs.de";
          "DATASOURCES_DEFAULT_DATABASE" = "passbolt";
          "DATASOURCES_DEFAULT_HOST" = "mariadb";
          "DATASOURCES_DEFAULT_PORT" = "3306";
          "DATASOURCES_DEFAULT_USERNAME" = "passbolt";
          "DATASOURCES_QUOTE_IDENTIFIER" = "true";
          "EMAIL_TRANSPORT_DEFAULT_HOST" = "mail.hhu.de";
          "EMAIL_TRANSPORT_DEFAULT_PORT" = "587";
          "EMAIL_TRANSPORT_DEFAULT_TLS" = "true";
          "EMAIL_TRANSPORT_DEFAULT_USERNAME" = "noreply-fscs";
          "PASSBOLT_KEY_EMAIL" = "fscs@hhu.de";
        };
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.passbolt.entrypoints" = "websecure";
          "traefik.http.routers.passbolt.rule" = "Host(`passbolt.hhu-fscs.de`)";
          "traefik.http.routers.passbolt.tls" = "true";
          "traefik.http.routers.passbolt.tls.certresolver" = "letsencrypt";
          "traefik.http.services.passbolt.loadbalancer.server.port" = "8080";
          "traefik.http.services.passbolt.loadbalancer.healthCheck.path" = "/";
        };
        environmentFiles = [ config.sops.secrets.passbolt.path ];
        volumes = [
          "${config.nix-tun.storage.persist.path}/passbolt/gpg:/etc/passbolt/gpg"
          "${config.nix-tun.storage.persist.path}/passbolt/jwtc:/etc/passbolt/jwtc"
        ];
        cmd = [
          "/usr/bin/wait-for.sh"
          "-t"
          "0"
          "mariadb:3306"
          "--"
          "/docker-entrypoint.sh"
        ];
        dependsOn = [
          "passbolt-mariadb"
        ];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=passbolt"
          "--network=passbolt_default"
        ];
      };
      systemd.services."docker-passbolt-passbolt" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-passbolt_default.service"
          "docker-volume-passbolt_gpg_volume.service"
          "docker-volume-passbolt_jwt_volume.service"
        ];
        requires = [
          "docker-network-passbolt_default.service"
          "docker-volume-passbolt_gpg_volume.service"
          "docker-volume-passbolt_jwt_volume.service"
        ];
        partOf = [
          "docker-compose-passbolt-root.target"
        ];
        wantedBy = [
          "docker-compose-passbolt-root.target"
        ];
      };

      # Networks
      systemd.services."docker-network-passbolt_default" = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "docker network rm -f passbolt_default";
        };
        script = ''
          docker network inspect passbolt_default || docker network create passbolt_default
        '';
        partOf = [ "docker-compose-passbolt-root.target" ];
        wantedBy = [ "docker-compose-passbolt-root.target" ];
      };

      # Volumes
      systemd.services."docker-volume-passbolt_database_volume" = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect passbolt_database_volume || docker volume create passbolt_database_volume
        '';
        partOf = [ "docker-compose-passbolt-root.target" ];
        wantedBy = [ "docker-compose-passbolt-root.target" ];
      };
      systemd.services."docker-volume-passbolt_gpg_volume" = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect passbolt_gpg_volume || docker volume create passbolt_gpg_volume
        '';
        partOf = [ "docker-compose-passbolt-root.target" ];
        wantedBy = [ "docker-compose-passbolt-root.target" ];
      };
      systemd.services."docker-volume-passbolt_jwt_volume" = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect passbolt_jwt_volume || docker volume create passbolt_jwt_volume
        '';
        partOf = [ "docker-compose-passbolt-root.target" ];
        wantedBy = [ "docker-compose-passbolt-root.target" ];
      };

      # Root service
      # When started, this will automatically create all resources and start
      # the containers. When stopped, this will teardown all resources.
      systemd.targets."docker-compose-passbolt-root" = {
        unitConfig = {
          Description = "Root target generated by compose2nix.";
        };
        wantedBy = [ "multi-user.target" ];
      };

    };
}
