{
  lib,
  config,
  ...
}:
{
  imports = [ ./meta.nix ];

  options.teenix.services.nextcloud = {
    enable = lib.mkEnableOption "nextcloud";
    hostname = lib.teenix.mkHostnameOption "nextcloud";
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

      teenix.persist.subvolumes.scanner = {
        backup = false;
        owner = toString config.containers.nextcloud.config.users.users.nextcloud.uid;
        mode = "0777";
      };

      teenix.services.traefik.httpServices.nextcloud = {
        router.rule = "Host(`${opts.hostname}`)";
        servers = [ "http://${config.containers.nextcloud.localAddress}" ];
        healthCheck = {
          enable = true;
          path = "/login";
        };
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
              hostPath = config.teenix.persist.subvolumes.scanner.path;
              mountPoint = "/var/lib/scanner";
              isReadOnly = false;
            };

            netapp = {
              hostPath = "/mnt/netapp/Nextcloud";
              mountPoint = "/var/lib/nextcloud/data";
              isReadOnly = false;
            };
          };

          sops.secrets = [ "nextcloud-admin-pass" ];
        };
      };
    };
}
