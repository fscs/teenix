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
  };

  config = lib.mkIf config.teenix.services.tuer-sensor.enable {
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
