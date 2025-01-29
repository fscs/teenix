{
  lib,
  config,
  ...
}:
{
  options.teenix.services.ntfy = {
    enable = lib.mkEnableOption "setup ntfy";
    hostname = lib.teenix.mkHostnameOption;
  };

  config =
    let
      opts = config.teenix.services.ntfy;
    in
    lib.mkIf opts.enable {
      teenix.services.traefik.services.ntfy = {
        router.rule = "Host(`${opts.hostname}`)";
        healthCheck.enable = true;
        servers = [ "http://${config.containers.ntfy.localAddress}:8080" ];
      };

      teenix.containers.ntfy = {
        config = {
          users.users.ntfy-sh.uid = 99;

          services.ntfy-sh = {
            enable = true;
            settings = {
              listen-http = ":8080";
              base-url = "https://${config.teenix.services.ntfy.hostname}";
              auth-default-access = "deny-all";
              auth-file = "/var/lib/ntfy/user.db";
            };
          };

          system.stateVersion = "23.11";
        };

        networking = {
          useResolvConf = true;
          ports.tcp = [ 8080 ];
        };

        mounts.data = {
          enable = true;
          ownerUid = config.containers.ntfy.config.users.users.ntfy-sh.uid;
        };
      };
    };
}
