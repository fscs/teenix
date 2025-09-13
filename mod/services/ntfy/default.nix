{
  lib,
  config,
  ...
}:
{
  imports = [ ./meta.nix ];

  options.teenix.services.ntfy = {
    enable = lib.mkEnableOption "ntfy";
    hostname = lib.teenix.mkHostnameOption "ntfy";
  };

  config =
    let
      cfg = config.teenix.services.ntfy;
    in
    lib.mkIf cfg.enable {
      teenix.services.traefik.httpServices.ntfy = {
        router.rule = "Host(`${cfg.hostname}`)";
        servers = [ "http://${config.containers.ntfy.localAddress}:8000" ];
      };

      teenix.containers.ntfy = {
        config = {
          systemd.services.ntfy-sh.serviceConfig.DynamicUser = lib.mkForce false;
          services.ntfy-sh = {
            enable = true;
            settings = {
              listen-http = ":8080";
              base-url = "https://${config.teenix.services.ntfy.hostname}";
              auth-default-access = "deny-all";
            };
          };

          system.stateVersion = "23.11";
        };

        networking.ports.tcp = [ 8080 ];

        mounts.data = {
          enable = true;
          name = "ntfy-sh";
        };
      };
    };
}
