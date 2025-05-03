{
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [ ./meta.nix ];
  
  options.teenix.services.inphimade = {
    enable = lib.mkEnableOption "setup inphimade";
    hostname = lib.teenix.mkHostnameOption "inphimade";
    secretsFile = lib.teenix.mkSecretsFileOption "inphimade";
  };

  config =
    let
      cfg = config.teenix.services.inphimade;
    in
    lib.mkIf cfg.enable {
      sops.secrets.inphimade-mysql-password = {
        sopsFile = cfg.secretsFile;
        key = "mysql-password";
      };

      sops.templates.inphimade.content = ''
        MYSQL_PASSWORD=${config.sops.placeholder.inphimade-mysql-password}
        WORDPRESS_DB_PASSWORD=${config.sops.placeholder.inphimade-mysql-password}
      '';

      teenix.persist.subvolumes.inphimade.directories = {
        mysql = {
          owner = "1000"; # TODO: Set the correct owner and mode
          mode = "0777";
        };
        wp = {
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
      virtualisation.oci-containers.containers.inphima-inphima-db = {
        image = "mysql:5.7";
        environment = {
          "MYSQL_DATABASE" = "inphimadb";
          "MYSQL_RANDOM_ROOT_PASSWORD" = "1";
          "MYSQL_USER" = "inphima";
        };
        environmentFiles = [ config.sops.templates.inphimade.path ];
        volumes = [
          "${config.teenix.persist.path}/inphimade/mysql:/var/lib/mysql"
        ];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=inphima-db"
          "--network=inphima_default"
        ];
      };
      systemd.services.docker-inphima-inphima-db = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-inphima_default.service"
          "docker-volume-inphima_db.service"
        ];
        requires = [
          "docker-network-inphima_default.service"
          "docker-volume-inphima_db.service"
        ];
        partOf = [
          "docker-compose-inphima-root.target"
        ];
        wantedBy = [
          "docker-compose-inphima-root.target"
        ];
      };
      virtualisation.oci-containers.containers.inphima-inphima-website = {
        image = "wordpress";
        environment = {
          "WORDPRESS_DB_HOST" = "inphima-db";
          "WORDPRESS_DB_NAME" = "inphimadb";
          "WORDPRESS_DB_USER" = "inphima";
        };
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.inphimadewp1.entrypoints" = "websecure";
          "traefik.http.routers.inphimadewp1.rule" = "Host(`${cfg.hostname}`) || Host(`www.${cfg.hostname}`)";
          "traefik.http.routers.inphimadewp1.tls" = "true";
          "traefik.http.routers.inphimadewp1.priority" = "9";
          "traefik.http.routers.inphimadewp1.tls.certresolver" = "letsencrypt";
          "traefik.http.routers.inphimadewp1.middlewares" = "hsts@file";
          "traefik.http.services.inphimadewp1.loadbalancer.server.port" = "80";
          "traefik.http.services.inphimadewp1.loadbalancer.healthCheck.path" = "/";
        };
        environmentFiles = [ config.sops.templates.inphimade.path ];
        volumes = [
          "${config.teenix.persist.path}/inphimade/wp:/var/www/html"
        ];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=inphima-website"
          "--network=inphima_default"
        ];
      };
      systemd.services.docker-inphima-inphima-website = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-inphima_default.service"
          "docker-volume-inphima_wp.service"
        ];
        requires = [
          "docker-network-inphima_default.service"
          "docker-volume-inphima_wp.service"
        ];
        partOf = [
          "docker-compose-inphima-root.target"
        ];
        wantedBy = [
          "docker-compose-inphima-root.target"
        ];
      };

      # Networks
      systemd.services.docker-network-inphima_default = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "docker network rm -f inphima_default";
        };
        script = ''
          docker network inspect inphima_default || docker network create inphima_default
        '';
        partOf = [ "docker-compose-inphima-root.target" ];
        wantedBy = [ "docker-compose-inphima-root.target" ];
      };

      # Volumes
      systemd.services.docker-volume-inphima_db = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect inphima_db || docker volume create inphima_db
        '';
        partOf = [ "docker-compose-inphima-root.target" ];
        wantedBy = [ "docker-compose-inphima-root.target" ];
      };
      systemd.services."docker-volume-inphima_wp" = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect inphima_wp || docker volume create inphima_wp
        '';
        partOf = [ "docker-compose-inphima-root.target" ];
        wantedBy = [ "docker-compose-inphima-root.target" ];
      };

      # Root service
      # When started, this will automatically create all resources and start
      # the containers. When stopped, this will teardown all resources.
      systemd.targets.docker-compose-inphima-root = {
        unitConfig = {
          Description = "Root target generated by compose2nix.";
        };
        wantedBy = [ "multi-user.target" ];
      };
    };
}
