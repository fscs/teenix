{
  lib,
  config,
  ...
}:
{
  imports = [ ./meta.nix ];

  options.teenix.services.uptime-kuma = {
    enable = lib.mkEnableOption "uptime-kuma";
    hostname = lib.teenix.mkHostnameOption "uptime-kuma";
  };

  config =
    let
      opts = config.teenix.services.uptime-kuma;
    in
    lib.mkIf opts.enable {
      teenix.services.traefik.httpServices.uptime-kuma = {
        router.rule = "Host(`${opts.hostname}`)";
        servers = [ "http://${config.containers.uptime-kuma.localAddress}:3001" ];
      };

      teenix.containers.uptime-kuma = {
        config = ./container.nix;

        networking = {
          useResolvConf = true;
          ports.tcp = [ 3001 ];
        };

        mounts.data.enable = true;
      };
    };
}
