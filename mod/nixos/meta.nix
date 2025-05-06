{ lib, ... }:
{
  options.teenix.meta.services = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          hostname = lib.mkOption {
            type = lib.types.str;
            description = "The hostname of the server.";
          };
          name = lib.mkOption {
            type = lib.types.str;
            description = "The name of the service.";
          };
        };
      }
    );
    description = "High-availability configuration for Teenix.";
  };
  options.teenix.meta.ha.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    example = true;
    description = ''
      Enable HA Loadbalencing
    '';
  };

}
