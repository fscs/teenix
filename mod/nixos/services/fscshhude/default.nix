{
  lib,
  config,
  ...
}:
{
  options.teenix.services.fscshhude = {
    enable = lib.mkEnableOption "setup fscshhude";
    secretsFile = lib.teenix.mkSecretsFileOption "fscshhude";
  };

  config =
    let
      cfg = config.teenix.services.fscshhude;

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
        hhu.acme = {
          email = "fscs@hhu.de";
          storage = "${config.services.traefik.dataDir}/hhucerts.json";
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
          router.tls.certResolver = "hhu";
          healthCheck.enable = true;
          servers = [ "http://${config.containers.fscshhude.localAddress}:8080" ];
        };

        hhu-fscs = {
          router.rule = "Host(`hhu-fscs.de`) || Host(`www.hhu-fscs.de`)";
          healthCheck.enable = true;
          servers = [ "http://${config.containers.fscshhude.localAddress}:8080" ];
        };
      };

      teenix.containers.fscshhude = {
        config = ./container.nix;

        networking = {
          useResolvConf = true;
          ports.tcp = [ 8080 ];
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
