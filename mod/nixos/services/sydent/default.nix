{
  lib,
  config,
  ...
}:
{
  options.teenix.services.sydent = {
    enable = lib.mkEnableOption "setup inphimade";
    hostname = lib.teenix.mkHostnameOption;
  };

  config =
    let
      opts = config.teenix.services.sydent;
    in
    lib.mkIf opts.enable {
      nix-tun.storage.persist.subvolumes."sydent".directories = {
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
          sydent = {
            image = "matrixdotorg/sydent";
            labels = {
              "traefik.enable" = "true";
              "traefik.http.routers.sydent.entrypoints" = "websecure";
              "traefik.http.routers.sydent.rule" = "Host(`${opts.hostname}`)";
              "traefik.http.routers.sydent.tls" = "true";
              "traefik.http.routers.sydent.tls.certresolver" = "letsencrypt";
              "traefik.http.services.sydent.loadbalancer.server.port" = "8090";
            };
            volumes = [
              "${config.nix-tun.storage.persist.path}/sydent/data:/data"
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
