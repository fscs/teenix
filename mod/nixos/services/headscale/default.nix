{ lib, config, ... }:
{
  options.teenix.services.headscale = {
    enable = lib.mkEnableOption "headscale VPN";
    hostname = lib.teenix.mkHostnameOption "headscale VPN";
    secretsFile = lib.teenix.mkSecretsFileOption "headscale VPN";
  };

  config = lib.mkIf config.teenix.services.headscale.enable {
    sops.secrets.headscale-oauth-client-secret = {
      sopsFile = config.teenix.services.headscale.secretsFile;
      key = "oauth-client-secret";
    };

    teenix.containers.headscale = {
      config = ./container.nix;

      mounts.sops.secrets = [ "headscale-oauth-client-secret" ];
    };
  };

}
