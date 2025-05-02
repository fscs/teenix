{
  lib,
  config,
  ...
}:
{
  options.teenix.services.sydent = {
    enable = lib.mkEnableOption "sydent";
  };

  config = lib.mkIf config.teenix.services.sydent.enable {
    teenix.persist.subvolumes.matrix.directories = {
      sydent-data = {
        owner = "1000";
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
        sydent = {
          image = "matrixdotorg/sydent";
          labels = {
            "traefik.enable" = "true";
            "traefik.http.routers.sydent.entrypoints" = "websecure";
            "traefik.http.routers.sydent.rule" = "Host(`${config.teenix.services.matrix.hostnames.sydent}`)";
            "traefik.http.routers.sydent.tls" = "true";
            "traefik.http.routers.sydent.tls.certresolver" = "letsencrypt";
            "traefik.http.services.sydent.loadbalancer.server.port" = "8090";
            "traefik.http.routers.sydent.middlewares" = "hsts@file";
          };
          volumes = [
            "${config.teenix.persist.subvolumes.matrix.path}/sydent-data:/data"
          ];
          environment = {
            SYDENT_SERVER_NAME = "inphima-sydent";
          };
          ports = [
            "8090"
          ];
        };
      };
    };
  };

}
