{ lib, config, ... }:
{
  options.teenix.services.atticd = {
    enable = lib.mkEnableOption "enable the attic binary cache";
    hostname = lib.teenix.mkHostnameOption;
    secretsFile = lib.teenix.mkSecretsFileOption "attic";
  };

  config =
    let
      cfg = config.teenix.services.atticd;
    in
    lib.mkIf cfg.enable {
      sops.secrets.atticd-jwt = {
        sopsFile = cfg.secretsFile;
        key = "jwt";
        mode = "444";
      };

      sops.templates.atticd.content = ''
        ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64="${config.sops.placeholder.atticd-jwt}"
      '';

      teenix.services.traefik.httpServices.attic = {
        router.rule = "Host(`${cfg.hostname}`)";
        healthCheck.enable = true;
        servers = [ "http://${config.containers.atticd.localAddress}:8080" ];
      };

      teenix.containers.atticd = {
        config = ./container.nix;

        networking.ports.tcp = [ 8080 ];

        mounts = {
          sops.templates = [ "atticd" ];

          data.enable = true;
        };
      };
    };
}
