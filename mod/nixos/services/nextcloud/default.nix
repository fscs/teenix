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
        owner = "${builtins.toString config.containers.nextcloud.config.users.users.nextcloud.uid}";
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

      services.traefik.staticConfigOptions.entryPoints = {
        websecure.proxyProtocol.insecure = true;
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
          useResolvConf = true;
          ports.tcp = [ 80 ];
        };

        extraConfig = {
          # in case nextcloud migrates its db
          timeoutStartSec = "15min";

          bindMounts.scanner = {
            hostPath = "${config.nix-tun.storage.persist.path}/scanner";
            mountPoint = "/var/lib/scanner";
            isReadOnly = false;
          };

          bindMounts.netapp = {
            hostPath = "/mnt/netapp/Nextcloud";
            mountPoint = "/var/lib/nextcloud/data";
            isReadOnly = false;
          };
        };

        mounts = {
          mysql.enable = true;

          data = {
            enable = true; 
            ownerUid = config.containers.nextcloud.config.users.users.nextcloud.uid;
          };
          
          sops.secrets = [
            config.sops.secrets.nextcloud-admin-pass
          ];
        };
      };
    };
}
