{
  lib,
  config,
  ...
}:
{
  imports = [ ./meta.nix ];

  options.teenix.services.cryptpad = {
    enable = lib.mkEnableOption "cryptpad";
    hostname = lib.teenix.mkHostnameOption "cryptpad";
  };

  config =
    let
      opts = config.teenix.services.cryptpad;
    in
    lib.mkIf opts.enable {
      teenix.services.traefik.httpServices.cryptpad = {
        router.rule = "Host(`${opts.hostname}`)";
        healthCheck.enable = true;
        servers = [
          "http://${config.containers.cryptpad.localAddress}:${toString config.containers.cryptpad.config.services.cryptpad.settings.httpPort}"
        ];
      };

      teenix.containers.cryptpad = {
        config = ./container.nix;

        networking = {
          useResolvConf = true;
          ports.tcp = [ config.containers.cryptpad.config.services.cryptpad.settings.httpPort ];
        };

        mounts = {
          data.enable = true;
        };
      };
    };
}
