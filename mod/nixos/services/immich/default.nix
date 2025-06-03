{
  lib,
  config,
  ...
}:
let
  cfg = config.teenix.services.immich;
in
{
  imports = [ ./meta.nix ];

  options.teenix.services.immich = {
    enable = lib.mkEnableOption "immich, a photo server";
    hostname = lib.teenix.mkHostnameOption "immich";
  };

  config = lib.mkIf cfg.enable {
    teenix.services.traefik.httpServices.immich = {
      router.rule = "Host(`${cfg.hostname}`)";
      servers = [
        "http://${config.containers.immich.localAddress}:${toString config.containers.immich.config.services.immich.port}"
      ];
    };

<<<<<<< Updated upstream
=======
    sops.secrets.immich-oauth-secret = {
      sopsFile = cfg.secretsFile;
      key = "oauth-secret";
    };

    sops.templates.immich-env-file.content = ''
      =${config.sops.placeholder.immich-oauth-secret}"
    '';

>>>>>>> Stashed changes
    teenix.containers.immich = {
      config = ./container.nix;

      networking = {
        useResolvConf = true;
        ports.tcp = [ config.containers.immich.config.services.immich.port ];
      };

      mounts = {
        postgres.enable = true;
        extra = {
          netapp = {
            hostPath = "/mnt/netapp/immich";
            mountPoint = config.services.immich.mediaLocation;
            isReadOnly = false;
          };
        };
      };
    };
  };
}
