{
  lib,
  config,
  ...
}:
{
  imports = [ ./meta.nix ];

  options.teenix.services.crabfit = {
    enable = lib.mkEnableOption "crab.fit, a meeting scheduler";
    hostnames = {
      frontend = lib.teenix.mkHostnameOption "frontend for crabfit";
      backend = lib.teenix.mkHostnameOption "backend for crabfit";
    };
  };

  config =
    let
      cfg = config.teenix.services.crabfit;
      crabfitCfg = config.containers.crabfit.config.services.crabfit;
    in
    lib.mkIf cfg.enable {
      teenix.services.traefik.httpServices = {
        crabfit-api = {
          router.rule = "Host(`${cfg.hostnames.backend}`)";
          healthCheck.enable = true;
          servers = [
            "http://${config.containers.crabfit.localAddress}:${toString crabfitCfg.api.port}"
          ];
        };
        crabfit = {
          router.rule = "Host(`${cfg.hostnames.frontend}`)";
          healthCheck.enable = true;
          servers = [
            "http://${config.containers.crabfit.localAddress}:${toString crabfitCfg.frontend.port}"
          ];
        };
      };

      teenix.containers.crabfit = {
        config = ./container.nix;

        networking = {
          useResolvConf = true;
          ports.tcp = [
            config.containers.crabfit.config.services.crabfit.frontend.port
            config.containers.crabfit.config.services.crabfit.api.port
          ];
        };

        mounts.postgres.enable = true;
      };
    };
}
