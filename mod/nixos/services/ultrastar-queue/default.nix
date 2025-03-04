{ lib, config, ... }:
{
  options.teenix.services.ultrastar-queue = {
    enable = lib.mkEnableOption "enable the ultrastar queue";
    hostname = lib.teenix.mkHostnameOption;
    secretsFile = lib.teenix.mkSecretsFileOption "ultrastar-queue";
  };

  config =
    let
      cfg = config.teenix.services.ultrastar-queue;
    in
    lib.mkIf cfg.enable {
      sops.secrets = {
        ultrastar-queue-jwt-signing-key = {
          sopsFile = cfg.secretsFile;
          key = "jwt-signing-key";
        };
        ultrastar-queue-admin-username = {
          sopsFile = cfg.secretsFile;
          key = "admin-username";
        };
        ultrastar-queue-admin-password = {
          sopsFile = cfg.secretsFile;
          key = "admin-password";
        };
      };

      sops.templates.ultrastar-queue.content = ''
        JWT_SIGNING_SECRET_KEY=${config.sops.placeholder.ultrastar-queue-jwt-signing-key}
        ADMIN_USERNAME=${config.sops.placeholder.ultrastar-queue-admin-username}
        ADMIN_PASSWORD=${config.sops.placeholder.ultrastar-queue-admin-password}
      '';

      teenix.containers.ultrastar-queue = {
        config = ./container.nix;

        mounts = {
          sops.templates = [ config.sops.templates.ultrastar-queue ];

          data.enable = true;

          extra.karaoke = {
            hostPath = "/mnt/netapp/Nextcloud";
            mountPoint = "/mnt/nextcloud-data";
          };
        };
      };
    };
}
