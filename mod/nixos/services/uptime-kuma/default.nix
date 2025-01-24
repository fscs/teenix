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
      nix-tun.storage.persist.subvolumes."uptime-kuma".directories = {
        "/data" = {
          owner = "${builtins.toString config.containers.uptime-kuma.config.users.users.root.uid}";
          mode = "0777";
        };
      };

      teenix.services.traefik.services."uptime-kuma" = {
        router.rule = "Host(`${opts.hostname}`)";
        healthCheck.enable = true;
        servers = [ "http://${config.containers.uptime-kuma.config.networking.hostName}:1301" ];
      };

      teenix.containers.uptime-kuma = {
        config = ./container.nix;
        networking.useResolvConf = true;
        networking.ports.tcp = [ 1301 ];
        mounts.extra.data = {
          mountPoint = "/var/lib/uptime-kuma/";
          isReadOnly = false;
        };
      };
    };
}
