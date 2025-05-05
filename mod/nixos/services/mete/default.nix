{
  lib,
  config,
  ...
}:
{
  options.teenix.services.mete = {
    enable = lib.mkEnableOption "mete";
    hostname = lib.teenix.mkHostnameOption "määääähte";
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
          };
        };
      };
    };

}
