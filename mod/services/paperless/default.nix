{
  lib,
  config,
  ...
}:
let
  cfg = config.teenix.services.paperless;

  secrets = [
    "paperless-admin-password"
    "paperless-oauth-client-secret"
  ];
in
{
  imports = [ ./meta.nix ];

  options.teenix.services.paperless = {
    enable = lib.mkEnableOption "paperless";
    hostname = lib.teenix.mkHostnameOption "paperless";
    secretsFile = lib.teenix.mkSecretsFileOption "paperless";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = lib.genAttrs secrets (name: {
      sopsFile = cfg.secretsFile;
      key = lib.removePrefix "paperless-" name;
    });

    sops.templates.paperless-environment.content = ''
      PAPERLESS_SOCIALACCOUNT_PROVIDERS=${builtins.toJSON config.containers.paperless.config.teenix.uglyOAuthOptionPassthrough}
    '';

    teenix.services.traefik.httpServices.paperless = {
      router.rule = "Host(`${cfg.hostname}`)";
      servers = [
        "http://${config.containers.paperless.localAddress}:${toString config.containers.paperless.config.services.paperless.port}"
      ];
    };

    teenix.persist.subvolumes.scanner.directories.paperless = {
      owner = config.containers.paperless.config.users.users.paperless.uid;
    };

    teenix.containers.paperless = {
      config = ./container.nix;

      networking = {
        useResolvConf = true;
        ports.tcp = [ config.containers.paperless.config.services.paperless.port ];
      };

      mounts = {
        sops.secrets = secrets;
        sops.templates = ["paperless-environment"];

        postgres.enable = true;

        extra = {
          media = {
            hostPath = "/mnt/netapp/paperless";
            mountPoint = config.containers.paperless.config.services.paperless.mediaDir;
            isReadOnly = false;
          };

          consumption = {
            hostPath = "${config.teenix.persist.subvolumes.scanner.path}/paperless";
            mountPoint = config.containers.paperless.config.services.paperless.consumptionDir;
            isReadOnly = false;
          };
        };
      };
    };
  };
}
