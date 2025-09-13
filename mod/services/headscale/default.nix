{ lib, config, ... }:
{
  imports = [ ./meta.nix ];

  options.teenix.services.headscale = {
    enable = lib.mkEnableOption "headscale VPN";
    hostname = lib.teenix.mkHostnameOption "headscale VPN";
    secretsFile = lib.teenix.mkSecretsFileOption "headscale VPN";
  };

  config = lib.mkIf config.teenix.services.headscale.enable {
    sops.secrets.headscale-oauth-client-secret = {
      sopsFile = config.teenix.services.headscale.secretsFile;
      mode = "0444";
      key = "oauth-client-secret";
    };

    teenix.services.traefik.httpServices.headscale = {
      router.rule = "Host(`${config.teenix.services.headscale.hostname}`)";
      servers = [
        "http://${config.containers.headscale.localAddress}:${toString config.containers.headscale.config.services.headscale.port}"
      ];
    };

    teenix.containers.headscale = {
      config = ./container.nix;

      mounts.sops.secrets = [ "headscale-oauth-client-secret" ];

      networking.ports.tcp = [ 8080 ];
    };
  };

}
