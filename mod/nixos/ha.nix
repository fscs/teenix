{ lib, config, ... }:
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
        };
      }
    );
    description = "High-availability configuration for Teenix.";
  };

  config = lib.mkIf config.teenix.meta.ha.enable {
    teenix.services.traefik.dynamicConfig =
      let
        ipPoolOf =
          name:
          lib.lists.findFirstIndex (x: x == name) (throw "unreachable") (
            lib.attrNames config.teenix.meta.services
          );
      in
      {
        http = {
          routers = lib.mapAttrs' (name: value: {
            name = name;
            value = {
              rule = "Host(`${value.hostname}`)";
              service = name;
              tls.certResolver = "letsencrypt";
              entrypoints = [ "websecure" ];
            };
          }) config.teenix.ha;

          services = lib.mapAttrs' (name: value: {
            name = name;
            value = {
              loadBalancer.servers = [
                { url = "http://192.18.${toString (ipPoolOf name)}.11:${toString value.port}"; }
                { url = "http://192.168.${toString (ipPoolOf name)}.11:${toString value.port}"; }
              ];
              loadBalancer.healthCheck = {
                path = "/";
                interval = "10s";
                timeout = "3s";
              };
            };
          }) config.teenix.ha;
        };
      };
  };
}
