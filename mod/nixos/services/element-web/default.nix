{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
{
  options.teenix.services.element-web = {
    enable = lib.mkEnableOption "setup element-web";
    hostname = lib.teenix.mkHostnameOption;
    matrixUrl = lib.mkOption {
      type = lib.types.str;
    };
  };

  config =
    let
      opts = config.teenix.services.element-web;
    in
    lib.mkIf opts.enable {
      teenix.services.traefik.services."element-web" = {
        router.rule = "Host(`${opts.hostname}`)";
        servers = [ "http://${config.containers.element-web.config.networking.hostName}:80" ];
        healthCheck.enable = true;
      };

      teenix.containers.element-web = {
        config = ./container.nix;
        networking.ports.tcp = [ 80 ];
      };
    };
}
