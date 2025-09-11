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
        "fscshhude-acme-eab-kid"
        "fscshhude-acme-eab-hmac-encoded"
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

      teenix.services.traefik.staticConfig.certificatesResolvers = {
        uniintern.acme = {
          email = "fscs@hhu.de";
          storage = "${config.teenix.persist.subvolumes.traefik.path}/hhucerts.json";
          tlsChallenge = { };
          caServer = "https://acme.sectigo.com/v2/OV";
          eab = {
            kid = config.sops.placeholder.fscshhude-acme-eab-kid;
            hmacEncoded = config.sops.placeholder.fscshhude-acme-eab-hmac-encoded;
          };
        };
      };

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
          id = "192.168.254";
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
