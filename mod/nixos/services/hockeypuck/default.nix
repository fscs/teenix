{ lib, config, ... }:
{
  options.teenix.services.hockeypuck = {
    enable = lib.mkEnableOption "enable the hockeypuck openpgp key server";
    hostname = lib.teenix.mkHostnameOption;
  };

  config =
    let
      cfg = config.teenix.services.hockeypuck;
    in
    lib.mkIf cfg.enable {
      teenix.services.traefik.services.hockeypuck = {
        router.rule = "Host(`${cfg.hostname}`)";
        healthCheck.enable = true;
        servers = [ "http://${config.containers.hockeypuck.localAddress}:11371" ];
      };

      teenix.containers.hockeypuck = {
        config = ./container.nix;

        networking.ports.tcp = [
          11371 # of course its undocumented that the http server runs on this port
          config.containers.hockeypuck.config.services.hockeypuck.port
        ];

        mounts = {
          postgres.enable = true;
          data.enable = true;
        };
      };
    };
}
