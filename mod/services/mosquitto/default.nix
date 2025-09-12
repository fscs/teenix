{
  lib,
  config,
  ...
}:
{
  imports = [ ./meta.nix ];

  options.teenix.services.mosquitto = {
    enable = lib.mkEnableOption "mosquitto";
    hostname = lib.teenix.mkHostnameOption "mosquitto";
    secretsFile = lib.teenix.mkSecretsFileOption "mosquitto";
  };

  config =
    let
      cfg = config.teenix.services.mosquitto;
    in
    lib.mkIf cfg.enable {
      sops.secrets.mosquitto-knut-password = {
        sopsFile = cfg.secretsFile;
        key = "knut-password";
      };

      teenix.services.traefik.entryPoints.mqtt = {
        port = 1883;
        protocol = "tcp";
      };

      teenix.services.traefik.tcpServices.mosquitto = {
        router = {
          rule = "HostSNI(`${cfg.hostname}`)";
          tls.enable = true;
          middlewares = [ "onlyhhudy" ];
          entryPoints = [ "mqtt" ];
        };
          
        servers = [
          "${config.containers.mosquitto.localAddress}:1883"
        ];
      };

      teenix.containers.mosquitto = {
        config = ./container.nix;

        networking.ports.tcp = [ 1883 ];

        mounts.sops.secrets = [ "mosquitto-knut-password" ];
      };
    };
}
