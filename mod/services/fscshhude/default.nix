{
  lib,
  config,
  ...
}:
{
  imports = [ ./meta.nix ];

  options.teenix.services.fscshhude = {
    enable = lib.mkEnableOption "fscshhude";
    secretsFile = lib.teenix.mkSecretsFileOption "fscshhude";
  };

  config =
    let
      cfg = config.teenix.services.fscshhude;
      containerConfig = config.containers.fscshhude.config;

      secrets = [
        "fscshhude-oauth-client-id"
        "fscshhude-oauth-client-secret"
        "fscshhude-signing-key"
      ];
    in
    lib.mkIf cfg.enable {
      sops.secrets = lib.genAttrs secrets (name: {
        sopsFile = cfg.secretsFile;
        key = lib.removePrefix "fscshhude-" name;
        mode = "0444";
      });

      sops.templates.fscshhude.content = ''
        CLIENT_ID=${config.sops.placeholder.fscshhude-oauth-client-id}
        CLIENT_SECRET=${config.sops.placeholder.fscshhude-oauth-client-secret}
        SIGNING_KEY=${config.sops.placeholder.fscshhude-signing-key}
      '';

      teenix.services.traefik.httpServices = {
        fscshhude = {
          router.rule = "Host(`fscs.hhu.de`)";
          router.tls.certResolver = "uniintern";
          healthCheck.enable = true;
          servers = [
            "http://${config.containers.fscshhude.localAddress}:${toString containerConfig.services.fscs-website-server.settings.port}"
          ];
        };

        hhu-fscs = {
          router.rule = "Host(`hhu-fscs.de`) || Host(`www.hhu-fscs.de`)";
          healthCheck.enable = true;
          inherit (config.teenix.services.traefik.httpServices.fscshhude) servers;
        };
      };

      teenix.containers.fscshhude = {
        config = ./container.nix;

        networking = {
          useResolvConf = true;
          ports.tcp = [
            containerConfig.services.fscs-website-server.settings.port
          ];
        };

        mounts = {
          postgres.enable = true;
          sops.templates = [ "fscshhude" ];

          data = {
            enable = true;
            name = "fscs-website-server";
          };
        };
      };
    };
}
