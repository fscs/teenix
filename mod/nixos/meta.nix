{ lib, ... }:
{
  options.teenix.meta.services = lib.mkOption {
    type = lib.types.attrs;
    default = { };
    example = {
      "fscshhude" = {
        enable = true;
      };
    };
    description = ''
      This is used to generate IPs fr the containers
    '';
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
