{
  config,
  lib,
  ...
}:
{
  options.teenix.services.traefik = {
    logging = {
      enable = lib.mkEnableOption "enable logging";
      filePath = lib.mkOption {
        type = lib.types.str;
        default = "/var/log/traefik.log";
      };
    };
  };

  config = lib.mkIf false {
    sops.secrets.traefik_static = {
      sopsFile = config.teenix.services.traefik.staticConfigPath;
      format = "binary";
      mode = "444";
    };

    services.traefik = {
      staticConfigOptions = {
        # unnessecary? maybe possily required for forward auth
        serversTransport.insecureSkipVerify = true;

        # unnessecary? idk wie wir die logs in grafana bekommen wollen ich fände es nice to have
        accesslog = lib.mkIf config.teenix.services.traefik.logging.enable {
          filePath = config.teenix.services.traefik.logging.filePath;
        };

        # turn server stuff? jo das muss für alle 30001-300010
        # können jetzt auch die normalen entrypoint options sein,
        # {
        #   udp_30001 = {
        #     address = ":30001/udp";
        #   };
        # };
      };
    };
  };
}
