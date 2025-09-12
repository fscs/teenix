{
  lib,
  config,
  ...
}:
{
  imports = [ ./meta.nix ];

  options.teenix.services.mediamtx = {
    enable = lib.mkEnableOption "media mtx";
    hostnames = {
      api = lib.teenix.mkHostnameOption "api url";
      rtsp = lib.teenix.mkHostnameOption "rtsp url";
    };
  };

  config =
    let
      cfg = config.teenix.services.mediamtx;
    in
    lib.mkIf cfg.enable {
      teenix.services.traefik.httpServices.mediamtx-api = {
        router.rule = "Host(`${cfg.hostnames.api}`)";
        router.middlewares = [ "onlyhhudy" ];
        healthCheck.enable = true;
        servers = [
          "http://${config.containers.mediamtx.localAddress}:9997"
        ];
      };

      teenix.services.traefik.entryPoints.rtsp = {
        port = 8554;
        protocol = "tcp";
      };

      teenix.services.traefik.tcpServices.mediamtx-rtsp = {
        router = {
          rule = "Host(`${cfg.hostnames.rtsp}`)";
          middlewares = [ "onlyhhudy" ];
          entryPoints = [ "rtsp" ];
        };

        servers = [
          "http://${config.containers.mediamtx.localAddress}:8554"
        ];
      };

      teenix.containers.mediamtx = {
        config = ./container.nix;

        networking.ports.tcp = [
          9997
          8554
        ];
      };
    };
}
