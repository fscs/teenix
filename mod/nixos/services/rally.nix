{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.teenix.services.rally = {
    enable = lib.mkEnableOption "setup rally";
    hostname = lib.teenix.mkHostnameOption;
    secretsFile = lib.teenix.mkSecretsFileOption "rally";
    postgresEnvFile = lib.mkOption {
      type = lib.types.path;
    };
  };

  config =
    let
      opts = config.teenix.services.rally;
    in
    lib.mkIf opts.enable {
      sops.secrets.rally = {
        sopsFile = opts.secretsFile;
        format = "binary";
        mode = "444";
      };

      sops.secrets.rally_db = {
        sopsFile = opts.postgresEnvFile;
        format = "binary";
        mode = "444";
      };

      teenix.persist.subvolumes.rally.directories = {
        "/postgres" = {
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
      virtualisation.oci-containers.containers."rally-rallly" = {
        image = "lukevella/rallly:latest";
        environment = {
          "ALLOWED_EMAILS" = "*@hhu.de";
          "DATABASE_URL" = "postgres://postgres:postgres@rallly_db/db";
          "NEXT_PUBLIC_BASE_URL" = "https://${config.teenix.services.rally.hostname}";
          "OIDC_NAME" = "INPhiMa Login";
          "OIDC_DISCOVERY_URL" =
            "https://auth.inphima.de/application/o/rally/.well-known/openid-configuration";
          "OIDC_CLIENT_ID" = "zKgUfGCFFCcdjUKzd0cmQ5omTi0U9LQhJzDrSLQm";
        };
        environmentFiles = [ config.sops.secrets.rally.path ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.rally.entrypoints" = "websecure";
          "traefik.http.routers.rally.rule" = "Host(`${opts.hostname}`)";
          "traefik.http.routers.rally.tls" = "true";
          "traefik.http.routers.rally.priority" = "1";
          "traefik.http.routers.rally.tls.certresolver" = "letsencrypt";
          "traefik.http.services.rally.loadbalancer.server.port" = "3000";
        };
        dependsOn = [
          "rally-rallly_db"
        ];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=rallly"
          "--network=rally_default"
        ];
      };
      systemd.services."docker-rally-rallly" = {
        serviceConfig = {
          Restart = lib.mkOverride 90 "always";
          RestartMaxDelaySec = lib.mkOverride 90 "1m";
          RestartSec = lib.mkOverride 90 "100ms";
          RestartSteps = lib.mkOverride 90 9;
        };
        after = [
          "docker-network-rally_default.service"
        ];
        requires = [
          "docker-network-rally_default.service"
        ];
        partOf = [
          "docker-compose-rally-root.target"
        ];
        wantedBy = [
          "docker-compose-rally-root.target"
        ];
      };
      virtualisation.oci-containers.containers."rally-rallly_db" = {
        image = "postgres:14.2";
        environmentFiles = [ config.sops.secrets.rally_db.path ];
        volumes = [
          "${config.teenix.persist.path}/rally/postgres:/var/www/html"
        ];
        log-driver = "journald";
        extraOptions = [
          "--health-cmd=pg_isready -U postgres"
          "--health-interval=5s"
          "--health-retries=5"
          "--health-timeout=5s"
          "--network-alias=rallly_db"
          "--network=rally_default"
        ];
      };
      systemd.services."docker-rally-rallly_db" = {
        serviceConfig = {
          Restart = lib.mkOverride 90 "always";
          RestartMaxDelaySec = lib.mkOverride 90 "1m";
          RestartSec = lib.mkOverride 90 "100ms";
          RestartSteps = lib.mkOverride 90 9;
        };
        after = [
          "docker-network-rally_default.service"
        ];
        requires = [
          "docker-network-rally_default.service"
        ];
        partOf = [
          "docker-compose-rally-root.target"
        ];
        wantedBy = [
          "docker-compose-rally-root.target"
        ];
      };

      # Networks
      systemd.services."docker-network-rally_default" = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "docker network rm -f rally_default";
        };
        script = ''
          docker network inspect rally_default || docker network create rally_default
        '';
        partOf = [ "docker-compose-rally-root.target" ];
        wantedBy = [ "docker-compose-rally-root.target" ];
      };

      # Root service
      # When started, this will automatically create all resources and start
      # the containers. When stopped, this will teardown all resources.
      systemd.targets."docker-compose-rally-root" = {
        unitConfig = {
          Description = "Root target generated by compose2nix.";
        };
        wantedBy = [ "multi-user.target" ];
      };
    };
}
