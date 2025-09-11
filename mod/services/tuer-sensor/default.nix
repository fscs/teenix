{
  config,
  inputs,
  lib,
  ...
}:
{
  imports = [ ./meta.nix ];

  options.teenix.services.tuer-sensor = {
    enable = lib.mkEnableOption "was-letzte-tuer, ein toller tür sensor";
    hostname = lib.teenix.mkHostnameOption "tuer-sensor";
  };

  config =
    let
      cfg = config.teenix.services.tuer-sensor;
    in
    lib.mkIf cfg.enable {
      teenix.services.traefik.httpServices = {
        tuer-sensor = {
          router.rule = "Host(`${cfg.hostname}`)";
          servers = [
            "http://${config.containers.tuer-sensor.localAddress}:${toString config.containers.tuer-sensor.config.services.was-letzte-tuer.port}"
          ];
        };

        tuer-sensor-private = {
          router = {
            rule = "Host(`${cfg.hostname}`) && PathPrefix(`/update`)";
            middlewares = [ "onlyhhudy" ];
          };

          inherit (config.teenix.services.traefik.httpServices.tuer-sensor) servers;
        };
      };

      teenix.containers.tuer-sensor = {
        config = {
          imports = [ inputs.was-letzte-tuer.nixosModules.was-letzte-tuer ];

          services.was-letzte-tuer = {
            enable = true;
            dataDir = "tuer-sensor";
          };

          system.stateVersion = "24.05";
        };

        # die historischen daten der tür sind jetzt wirklich nicht so interessant
        backup = false;

        mounts.data.enable = true;

        networking.ports.tcp = [
          config.containers.tuer-sensor.config.services.was-letzte-tuer.port
        ];
      };
    };
}
