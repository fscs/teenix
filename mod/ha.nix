{
  lib,
  config,
  ...
}:
{
  options.teenix.ha = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          hostname = lib.mkOption {
            type = lib.types.str;
            description = "The hostname of the server.";
          };
          port = lib.mkOption {
            type = lib.types.number;
            description = "The port of the service.";
          };
          database = lib.mkOption {
            type = lib.types.nullOr (
              lib.types.submodule {
                options = {
                  name = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    default = null;
                    description = "Optional database name to auto-create and expose via PgBouncer.";
                  };
                  username = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    default = null;
                    description = "Owner of the database (will also be created if missing).";
                  };
                };
              }
            );
            default = null;
            description = "Database configuration (name & owner).";
          };
        };
      }
    );
    description = "High-availability configuration for Teenix.";
  };

  config = lib.mkIf config.teenix.meta.ha.enable {
    teenix.services.traefik.httpServices =
      let
        ipPoolOf =
          name:
          lib.lists.findFirstIndex (x: x == name) (throw "unreachable") (
            lib.attrNames config.teenix.meta.services
          );
      in
      lib.mapAttrs' (name: v: {
        name = name;
        value = {
          router.rule = "Host(`${v.hostname}`)";
          healthCheck.enable = true;
          servers = [
            "http://192.18.${toString (ipPoolOf name)}.11:${toString v.port}"
          ];
        };
      }) config.teenix.ha;
  };
}
