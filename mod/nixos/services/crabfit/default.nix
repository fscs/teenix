{
  lib,
  config,
  ...
}:
{
  imports = [ ./meta.nix ];

  options.teenix.services.crabfit = {
    enable = lib.mkEnableOption "crab.fit, a meeting scheduler";
    secretsFile = lib.teenix.mkSecretsFileOption "crab.fit";
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
      sops.secrets = {
        crabfit-google-client-id = {
          sopsFile = cfg.secretsFile;
          key = "google-client-id";
        };
        crabfit-google-client-secret = {
          sopsFile = cfg.secretsFile;
          key = "google-client-secret";
        };
      };

      sops.templates.crabfit.content = ''
        NEXT_PUBLIC_GOOGLE_CLIENT_ID=${config.sops.placeholder.crabfit-google-client-id}
        NEXT_PUBLIC_GOOGLE_API_KEY=${config.sops.placeholder.crabfit-google-client-secret}
      '';

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
        config = {
          systemd.services.crabfit-frontend.serviceConfig.EnvironmentFile = config.sops.templates.crabfit.path;

          services.crabfit = {
            enable = true;
            frontend.host = config.teenix.services.crabfit.hostnames.frontend;
            api = {
              host = config.teenix.services.crabfit.hostnames.backend;
              environment.API_LISTEN = "0.0.0.0:${toString crabfitCfg.api.port}";
            };
          };

          system.stateVersion = "24.11";
        };

        networking = {
          useResolvConf = true;
          ports.tcp = [
            config.containers.crabfit.config.services.crabfit.frontend.port
            config.containers.crabfit.config.services.crabfit.api.port
          ];
        };

        mounts = {
          postgres.enable = true;
          sops.templates = [ "crabfit" ];
        };
      };
    };
}
