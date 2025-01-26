{ lib
, config
, ...
}:
{
  options.teenix.services.uptime-kuma = {
    enable = lib.mkEnableOption "setup uptime-kuma";
    hostname = lib.teenix.mkHostnameOption;
  };

  config =
    let
      opts = config.teenix.services.uptime-kuma;
    in
    lib.mkIf opts.enable {
      teenix.services.traefik.services.uptime-kuma = {
        router.rule = "Host(`${opts.hostname}`)";
        healthCheck.enable = true;
        servers = [ "http://${config.containers.uptime-kuma.config.networking.hostName}:3001" ];
      };

      teenix.containers.uptime-kuma = {
        config = ./container.nix;

        networking.useResolvConf = true;
        networking.ports.tcp = [ 3001 ];

        mounts.data = {
          enable = true;
          ownerUid = config.containers.uptime-kuma.config.users.users.root.uid;
        };
      };
    };
}
