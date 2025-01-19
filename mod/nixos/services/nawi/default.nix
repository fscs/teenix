{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.teenix.services.nawi = {
    enable = lib.mkEnableOption "setup nawi";
    hostname = lib.teenix.mkHostnameOption;
    secretsFile = lib.teenix.mkSecretsFileOption "fsnawide";
    mariaEnvFile = lib.mkOption {
      type = lib.types.path;
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
        sopsFile = opts.secretsFile;
        format = "binary";
        mode = "444";
      };

      nix-tun.storage.persist.subvolumes."nawi".directories = {
        "/mysql" = {
          owner = "1000"; # TODO: Set the correct owner and mode
          mode = "0777";
        };
        "/wp" = {
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
      virtualisation.oci-containers.containers."nawi-nawi-db" = {
        image = "mysql:5.7";
        environment = {
          "MYSQL_DATABASE" = "nawidb";
          "MYSQL_RANDOM_ROOT_PASSWORD" = "1";
          "MYSQL_USER" = "nawi";
        };
        environmentFiles = [ config.sops.secrets.nawi_mariadb.path ];
        volumes = [
          "${config.nix-tun.storage.persist.path}/nawi/mysql:/var/lib/mysql"
        ];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=nawi-db"
          "--network=nawi_default"
        ];
      };
      systemd.services."docker-nawi-nawi-db" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-nawi_default.service"
          "docker-volume-nawi_db.service"
        ];
        requires = [
          "docker-network-nawi_default.service"
          "docker-volume-nawi_db.service"
        ];
        partOf = [
          "docker-compose-nawi-root.target"
        ];
        wantedBy = [
          "docker-compose-nawi-root.target"
        ];
      };
      virtualisation.oci-containers.containers."nawi-nawi-website" = {
        image = "wordpress:latest";
        environment = {
          "WORDPRESS_DB_HOST" = "nawi-db";
          "WORDPRESS_DB_NAME" = "nawidb";
          "WORDPRESS_DB_USER" = "nawi";
        };
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.nawi.entrypoints" = "websecure";
          "traefik.http.routers.nawi.rule" =
            "Host(`nawi.inphima.de`) || Host(`${opts.hostname}`) || Host(`www.${opts.hostname}`)";
          "traefik.http.routers.nawi.tls" = "true";
          "traefik.http.routers.nawi.tls.certresolver" = "letsencrypt";
          "traefik.http.services.nawi.loadbalancer.server.port" = "80";
          # "traefik.http.services.nawi.loadbalancer.healthCheck.path" = "/";
        };
        environmentFiles = [ config.sops.secrets.nawi.path ];
        volumes = [
          "${config.nix-tun.storage.persist.path}/nawi/wp:/var/www/html"
        ];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=nawi-website"
          "--network=nawi_default"
        ];
      };
      systemd.services."docker-nawi-nawi-website" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-nawi_default.service"
          "docker-volume-nawi_wp.service"
        ];
        requires = [
          "docker-network-nawi_default.service"
          "docker-volume-nawi_wp.service"
        ];
        partOf = [
          "docker-compose-nawi-root.target"
        ];
        wantedBy = [
          "docker-compose-nawi-root.target"
        ];
      };

      # Networks
      systemd.services."docker-network-nawi_default" = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "docker network rm -f nawi_default";
        };
        script = ''
          docker network inspect nawi_default || docker network create nawi_default
        '';
        partOf = [ "docker-compose-nawi-root.target" ];
        wantedBy = [ "docker-compose-nawi-root.target" ];
      };

      # Volumes
      systemd.services."docker-volume-nawi_db" = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect nawi_db || docker volume create nawi_db
        '';
        partOf = [ "docker-compose-nawi-root.target" ];
        wantedBy = [ "docker-compose-nawi-root.target" ];
      };
      systemd.services."docker-volume-nawi_wp" = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect nawi_wp || docker volume create nawi_wp
        '';
        partOf = [ "docker-compose-nawi-root.target" ];
        wantedBy = [ "docker-compose-nawi-root.target" ];
      };

      # Root service
      # When started, this will automatically create all resources and start
      # the containers. When stopped, this will teardown all resources.
      systemd.targets."docker-compose-nawi-root" = {
        unitConfig = {
          Description = "Root target generated by compose2nix.";
        };
        wantedBy = [ "multi-user.target" ];
      };

    };
}
