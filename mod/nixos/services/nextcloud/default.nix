{
  lib,
  config,
  ...
}:
{
  options.teenix.services.nextcloud = {
    enable = lib.mkEnableOption "setup nextcloud";
    hostname = lib.teenix.mkHostnameOption;
    secretsFile = lib.teenix.mkSecretsFileOption "nextcloud";
    extraApps = lib.mkOption {
      description = "nextcloud apps to install";
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config =
    let
      opts = config.teenix.services.nextcloud;
    in
    lib.mkIf opts.enable {
      sops.secrets.nextcloud-admin-pass = {
        sopsFile = opts.secretsFile;
        key = "admin-pass";
        mode = "444";
      };

      nix-tun.storage.persist.subvolumes.scanner = {
        owner = toString config.containers.nextcloud.config.users.users.nextcloud.uid;
        mode = "0777";
      };

      teenix.services.traefik.services.nextcloud = {
        router.rule = "Host(`${opts.hostname}`)";
        servers = [ "http://${config.containers.nextcloud.localAddress}" ];
        healthCheck = {
          enable = true;
          path = "/login";
        };
      };

      teenix.services.traefik.redirects.cloud_inphima = {
        from = "cloud.inphima.de";
        to = "nextcloud.inphima.de";
      };

      teenix.services.traefik.redirects.klausur_inphima = {
        from = "klausur.inphima.de";
        to = "nextcloud.inphima.de/s/K6xSKSXmJRQAiia";
      };

      teenix.containers.nextcloud = {
        config = ./container.nix;

        networking = {
          id = "192.168.255";
          useResolvConf = true;
          ports.tcp = [ 80 ];
        };

        # dont EVER lower this value. on startup, nextcloud might migrate its database and if that
        # process is interrupted we are screwed
        extraConfig.timeoutStartSec = "15min";

        mounts = {
          mysql.enable = true;

          data = {
            enable = true;
            ownerUid = config.containers.nextcloud.config.users.users.nextcloud.uid;
          };

          extra = {
            scanner = {
              hostPath = config.nix-tun.storage.persist.subvolumes.scanner.path;
              mountPoint = "/var/lib/scanner";
              isReadOnly = false;
            };

            netapp = {
              hostPath = "/mnt/netapp/Nextcloud";
              mountPoint = "/var/lib/nextcloud/data";
              isReadOnly = false;
            };
          };

          sops.secrets = [
            config.sops.secrets.nextcloud-admin-pass
          ];
        };
      };
    };
}
