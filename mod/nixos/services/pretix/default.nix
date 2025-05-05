{
  lib,
  config,
  ...
}:
{
  options.teenix.services.pretix = {
    enable = lib.mkEnableOption "pretix";
    hostname = lib.teenix.mkHostnameOption "pretix";
    email = lib.mkOption {
      type = lib.types.str;
    };
  };

  config =
    let
      opts = config.teenix.services.pretix;
    in
    lib.mkIf opts.enable {
      teenix.services.traefik.httpServices.pretix = {
        router.rule = "Host(`${opts.hostname}`)";
        servers = [ "http://${config.containers.pretix.localAddress}" ];
      };

      teenix.containers.pretix = {
        config = {
          services.pretix = {
            enable = true;
            database.createLocally = true;
            nginx.domain = opts.hostname;
            settings = {
              mail.from = "${opts.email}";
              pretix = {
                instance_name = "${opts.hostname}";
                url = "https://${opts.hostname}";
              };
            };
          };

          system.stateVersion = "23.11";
        };

        networking = {
          useResolvConf = true;
          ports.tcp = [ 80 ];
        };

        mounts.postgres.enable = true;
      };
    };
}
