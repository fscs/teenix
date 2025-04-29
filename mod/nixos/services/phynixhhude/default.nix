{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.teenix.services.phynixhhude = {
    enable = lib.mkEnableOption "phynixhhude";
    hostname = lib.teenix.mkHostnameOption;
    secretsFile = lib.teenix.mkSecretsFileOption "phynixhhude";
  };

  config =
    let
      opts = config.teenix.services.phynixhhude;
    in
    lib.mkIf opts.enable {
      sops.secrets.phynixhhude-mysql-password = {
        sopsFile = opts.secretsFile;
        key = "mysql-password";
      };

      sops.templates.phynixhhude.content = ''
        MYSQL_PASSWORD=${config.sops.placeholder.phynixhhude-mysql-password}
        WORDPRESS_DB_PASSWORD=${config.sops.placeholder.phynixhhude-mysql-password}
      '';

      teenix.persist.subvolumes.phynixhhude.directories = {
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
      virtualisation.oci-containers.containers.phynix-phynix-db = {
        image = "mysql:5.7";
        environment = {
          "MYSQL_DATABASE" = "phynixdb";
          "MYSQL_RANDOM_ROOT_PASSWORD" = "1";
          "MYSQL_USER" = "phynix";
        };
        environmentFiles = [ config.sops.templates.phynixhhude.path ];
        volumes = [
          "${config.teenix.persist.path}/phynixhhude/mysql:/var/lib/mysql"
        ];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=phynix-db"
          "--network=phynix_default"
        ];
      };
      systemd.services.docker-phynix-phynix-db = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-phynix_default.service"
          "docker-volume-phynix_db.service"
        ];
        requires = [
          "docker-network-phynix_default.service"
          "docker-volume-phynix_db.service"
        ];
        partOf = [
          "docker-compose-phynix-root.target"
        ];
        wantedBy = [
          "docker-compose-phynix-root.target"
        ];
      };
      virtualisation.oci-containers.containers.phynix-phynix-website = {
        image = "wordpress";
        environment = {
          "WORDPRESS_DB_HOST" = "phynix-db";
          "WORDPRESS_DB_NAME" = "phynixdb";
          "WORDPRESS_DB_USER" = "phynix";
        };
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.phynixhhudewp1.entrypoints" = "websecure";
          "traefik.http.routers.phynixhhudewp1.rule" =
            "Host(`${opts.hostname}`) || Host(`www.${opts.hostname}`)";
          "traefik.http.routers.phynixhhudewp1.tls" = "true";
          "traefik.http.routers.phynixhhudewp1.priority" = "1";
          "traefik.http.routers.phynixhhudewp1.tls.certresolver" = "letsencrypt";
          "traefik.http.services.phynixhhudewp1.loadbalancer.server.port" = "80";
          "traefik.http.services.phynixhhudewp1.loadbalancer.healthCheck.path" = "/";
        };
        environmentFiles = [ config.sops.templates.phynixhhude.path ];
        volumes = [
          "${config.teenix.persist.path}/phynixhhude/wp:/var/www/html"
        ];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=phynix-website"
          "--network=phynix_default"
        ];
      };
      systemd.services.docker-phynix-phynix-website = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-phynix_default.service"
          "docker-volume-phynix_wp.service"
        ];
        requires = [
          "docker-network-phynix_default.service"
          "docker-volume-phynix_wp.service"
        ];
        partOf = [
          "docker-compose-phynix-root.target"
        ];
        wantedBy = [
          "docker-compose-phynix-root.target"
        ];
      };

      # Networks
      systemd.services.docker-network-phynix_default = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "docker network rm -f phynix_default";
        };
        script = ''
          docker network inspect phynix_default || docker network create phynix_default
        '';
        partOf = [ "docker-compose-phynix-root.target" ];
        wantedBy = [ "docker-compose-phynix-root.target" ];
      };

      # Volumes
      systemd.services.docker-volume-phynix_db = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect phynix_db || docker volume create phynix_db
        '';
        partOf = [ "docker-compose-phynix-root.target" ];
        wantedBy = [ "docker-compose-phynix-root.target" ];
      };
      systemd.services."docker-volume-phynix_wp" = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect phynix_wp || docker volume create phynix_wp
        '';
        partOf = [ "docker-compose-phynix-root.target" ];
        wantedBy = [ "docker-compose-phynix-root.target" ];
      };

      # Root service
      # When started, this will automatically create all resources and start
      # the containers. When stopped, this will teardown all resources.
      systemd.targets.docker-compose-phynix-root = {
        unitConfig = {
          Description = "Root target generated by compose2nix.";
        };
        wantedBy = [ "multi-user.target" ];
      };
    };
}
