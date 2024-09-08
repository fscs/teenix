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

      teenix.services.traefik.services."mete" = {
        router =
          {
            rule = "Host(`${opts.hostname}`)";
            middlewares = [ "meteredirect" "meteauth" ];
          };
        servers = [ "http://172.17.0.3:8080" ];
      };

      teenix.services.traefik.services."mete-summary" = {
        router.rule = "Host(`${opts.hostname-summary}`)";
        #TODO: Set the adderees dynamically maybe traefix docker impl
        servers = [ "http://172.17.0.2:5000" ];
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
