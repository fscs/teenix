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
    hostname = lib.mkOption {
      type = lib.types.str;
    };
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

      containers.element-web = {
        ephemeral = true;
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.107.10";
        localAddress = "192.168.107.11";

        specialArgs = {
          inherit inputs pkgs;
          host-config = config;
        };

        config = import ./container.nix;
      };
    };
}
