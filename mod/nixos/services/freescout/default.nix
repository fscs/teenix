{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
{
  options.teenix.services.freescout = {
    enable = lib.mkEnableOption "setup freescout";
    secretsFile = lib.teenix.mkSecretsFileOption "freescout";
    hostname = lib.teenix.mkHostnameOption;
    mariaEnvFile = lib.mkOption {
      type = lib.types.path;
      description = "path to the sops secret file for the freescout website Server";
    };
  };

  config =
    let
      opts = config.teenix.services.freescout;
    in
    lib.mkIf opts.enable {
      sops.secrets.freescout = {
        sopsFile = opts.secretsFile;
        format = "binary";
        mode = "444";
      };

      sops.secrets.freescout_mariadb = {
        sopsFile = opts.mariaEnvFile;
        format = "binary";
        mode = "444";
      };

      nix-tun.storage.persist.subvolumes.freescout.directories = {
        "/mysql" = {
          owner = "1000"; # TODO: Set the correct owner and mode
          mode = "0777";
        };
        "/data" = {
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
      virtualisation.oci-containers.containers.freescout-freescout-db = {
        image = "tiredofit/mariadb";
        environment = {
          "DB_NAME" = "freescout";
          "DB_USER" = "freescout";
          "CONTAINER_NAME" = "freescout-db";
        };
        log-driver = "journald";
        environmentFiles = [ config.sops.secrets.freescout_mariadb.path ];
        volumes = [
          "${config.nix-tun.storage.persist.path}/freescout/mysql:/var/lib/mysql"
        ];
        extraOptions = [
          "--network-alias=freescout-db"
          "--network=freescout_default"
        ];
      };
      systemd.services.docker-freescout-freescout-db = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-freescout_default.service"
          "docker-volume-freescout_db.service"
        ];
        requires = [
          "docker-network-freescout_default.service"
          "docker-volume-freescout_db.service"
        ];
        partOf = [
          "docker-compose-freescout-root.target"
        ];
        wantedBy = [
          "docker-compose-freescout-root.target"
        ];
      };
      virtualisation.oci-containers.containers.freescout-freescout = {
        image = "tiredofit/freescout";
        environment = {
          DB_HOST = "freescout-db";
          DB_NAME = "freescout";
          SITE_URL = "https://${opts.hostname}";
          ADMIN_EMAIL = "admin@admin.com";
          ENABLE_SSL_PROXY = "false";
          DISPLAY_ERRORS = "false";
          TIMEZONE = "Europe/Berlin";
        };
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.freescout.entrypoints" = "websecure";
          "traefik.http.routers.freescout.rule" = "Host(`${opts.hostname}`)";
          "traefik.http.routers.freescout.tls" = "true";
          "traefik.http.routers.freescout.tls.certresolver" = "letsencrypt";
          "traefik.http.services.freescout.loadbalancer.server.port" = "80";
          "traefik.http.services.freescout.loadbalancer.healthCheck.path" = "/";
        };
        environmentFiles = [ config.sops.secrets.freescout.path ];
        volumes = [
          "${config.nix-tun.storage.persist.path}/freescout/data:/data"
        ];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=freescout-website"
          "--network=freescout_default"
        ];
      };
      systemd.services.docker-freescout-freescout-website = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-freescout_default.service"
          "docker-volume-freescout.service"
        ];
        requires = [
          "docker-network-freescout_default.service"
          "docker-volume-freescout.service"
        ];
        partOf = [
          "docker-compose-freescout-root.target"
        ];
        wantedBy = [
          "docker-compose-freescout-root.target"
        ];
      };

      # Networks
      systemd.services.docker-network-freescout_default = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "docker network rm -f freescout_default";
        };
        script = ''
          docker network inspect freescout_default || docker network create freescout_default
        '';
        partOf = [ "docker-compose-freescout-root.target" ];
        wantedBy = [ "docker-compose-freescout-root.target" ];
      };

      # Volumes
      systemd.services.docker-volume-freescout_db = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect freescout_db || docker volume create freescout_db
        '';
        partOf = [ "docker-compose-freescout-root.target" ];
        wantedBy = [ "docker-compose-freescout-root.target" ];
      };
      systemd.services.docker-volume-freescout = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect freescout || docker volume create freescout
        '';
        partOf = [ "docker-compose-freescout-root.target" ];
        wantedBy = [ "docker-compose-freescout-root.target" ];
      };

      # Root service
      # When started, this will automatically create all resources and start
      # the containers. When stopped, this will teardown all resources.
      systemd.targets.docker-compose-freescout-root = {
        unitConfig = {
          Description = "Root target generated by compose2nix.";
        };
        wantedBy = [ "multi-user.target" ];
      };
    };
}
