{
  lib,
  config,
  ...
}:
{
  options.teenix.services.mete = {
    enable = lib.mkEnableOption "setup inphimade";
    hostname = lib.teenix.mkHostnameOption;
    hostname-summary = lib.mkOption {
      type = lib.types.str;
    };
  };

  config =
    let
      opts = config.teenix.services.mete;
    in
    lib.mkIf opts.enable {
      teenix.persist.subvolumes.mete.directories = {
        "/db" = {
          owner = "1000"; # TODO: Set the correct owner and mode
          mode = "0777";
        };
        "/drinks" = {
          owner = "1000"; # TODO: Set the correct owner and mode
          mode = "0777";
        };
      };

      virtualisation.docker.rootless = {
        enable = true;
        setSocketVariable = true;
      };

      virtualisation.oci-containers = {
        backend = "docker";
        containers = {
          mete = {
            image = "ghcr.io/fscs/mete:wip-fscs";
            labels = {
              "traefik.enable" = "true";
              # Certificate
              "traefik.http.services.mete.loadbalancer.server.port" = "8080";
              "traefik.http.services.mete.loadbalancer.healthCheck.path" = "/";
              # Mete Secure
              "traefik.http.routers.metesecure.rule" = "Host(`metesecure.hhu-fscs.de`)";
              "traefik.http.routers.metesecure.tls" = "true";
              "traefik.http.routers.metesecure.tls.certresolver" = "letsencrypt";
              "traefik.http.routers.metesecure.service" = "mete";
              "traefik.http.routers.metesecure.middlewares" = "authentik@file,hsts@file";
            };
            volumes = [
              "${config.teenix.persist.path}/mete/db:/app/var"
              "${config.teenix.persist.path}/mete/drinks:/app/public/system/drinks"
            ];
            ports = [
              "8080"
            ];
          };
          gorden-summary = {
            image = "ghcr.io/fscs/gorden-summary:master";
            volumes = [
              "${config.teenix.persist.path}/mete/db:/var/docker-services/gorden/var:ro"
            ];
            ports = [
              "5000"
            ];
            labels = {
              "traefik.enable" = "true";
              # Certificate
              "traefik.http.routers.gorden-summary.tls" = "true";
              "traefik.http.routers.gorden-summary.entrypoints" = "websecure";
              "traefik.http.routers.gorden-summary.tls.certresolver" = "letsencrypt";
              "traefik.http.routers.gorden-summary.middlewares" = "authentik@file,hsts";
              "traefik.http.routers.gorden-summary.rule" = "Host(`robert.hhu-fscs.de`)";
              "traefik.http.services.gorden-summary.loadbalancer.server.port" = "5000";
            };
          };
        };
      };
    };

}
