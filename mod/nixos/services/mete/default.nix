{ lib
, config
, ...
}: {
  options.teenix.services.mete =
    let
      t = lib.types;
    in
    {
      enable = lib.mkEnableOption "setup inphimade";
      hostname = lib.mkOption {
        type = t.str;
      };
      hostname-summary = lib.mkOption {
        type = t.str;
      };
    };

  config =
    let
      opts = config.teenix.services.mete;
    in
    lib.mkIf opts.enable {
      nix-tun.storage.persist.subvolumes."mete".directories = {
        "/db" = {
          owner = "1000"; #TODO: Set the correct owner and mode
          mode = "0777";
        };
        "/drinks" = {
          owner = "1000"; #TODO: Set the correct owner and mode
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
              "traefik.http.routers.mete.tls" = "true";
              "traefik.http.routers.mete.tls.certresolver" = "letsencrypt";
              "traefik.http.routers.mete.rule" = "Host(`mete.hhu-fscs.de`)";
              "traefik.http.routers.mete.middlewares" = "meteauth@file,meteredirect@file";
              "traefik.http.services.mete.loadbalancer.server.port" = "8080";
              "traefik.http.services.mete.loadbalancer.healthCheck.path" = "/";
              # Mete Secure
              "traefik.http.middlewares.meteredirect.redirectregex.regex" = "https://mete.hhu-fscs.de/(.*?)((/deposit)|(/retrieve)|(/transaction))(.*)";
              "traefik.http.middlewares.meteredirect.redirectregex.replacement" = "https://mete.hhu-fscs.de/$1";
              "traefik.http.routers.metesecure.rule" = "Host(`metesecure.hhu-fscs.de`)";
              "traefik.http.routers.metesecure.tls" = "true";
              "traefik.http.routers.metesecure.tls.certresolver" = "letsencrypt";
              "traefik.http.routers.metesecure.service" = "mete";
              "traefik.http.routers.metesecure.middlewares" = "authentik@file";
            };
            volumes = [
              "${config.nix-tun.storage.persist.path}/mete/db:/app/var"
              "${config.nix-tun.storage.persist.path}/mete/drinks:/app/public/system/drinks"
            ];
            ports = [
              "8080"
            ];
          };
          gorden-summary = {
            image = "ghcr.io/fscs/gorden-summary:master";
            volumes = [
              "${config.nix-tun.storage.persist.path}/mete/db:/var/docker-services/gorden/var:ro"
            ];
            ports = [
              "5000"
            ];
          };
        };
      };
    };


}
