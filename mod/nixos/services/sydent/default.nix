{ lib
, config
, ...
}: {
  options.teenix.services.sydent =
    let
      t = lib.types;
    in
    {
      enable = lib.mkEnableOption "setup inphimade";
      hostname = lib.mkOption {
        type = t.str;
      };
    };

  config =
    let
      opts = config.teenix.services.sydent;
    in
    lib.mkIf opts.enable {
      nix-tun.storage.persist.subvolumes."sydent".directories = {
        "/db" = {
          owner = "1000"; #TODO: Set the correct owner and mode
          mode = "0777";
        };
        "/drinks" = {
          owner = "1000"; #TODO: Set the correct owner and mode
          mode = "0777";
        };
      };

      teenix.services.traefik.services."sydent" = {
        router =
          {
            rule = "Host(`${opts.hostname}`)";
          };
        servers = [ "http://172.17.0.4:8090" ];
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
