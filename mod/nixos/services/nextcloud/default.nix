{ lib
, config
, pkgs
, inputs
, ...
}: {
  options.teenix.services.nextcloud =
    let
      t = lib.types;
    in
    {
      enable = lib.mkEnableOption "setup nextcloud";
      hostname = lib.mkOption {
        type = t.str;
      };
      secretsFile = lib.mkOption {
        type = t.path;
        description = "path to the sops secret file for the adminPass";
      };
      extraApps = lib.mkOption {
        description = "nextcloud apps to install";
        type = t.listOf t.str;
        default = [ ];
      };
    };

  config =
    let
      opts = config.teenix.services.nextcloud;
    in
    lib.mkIf opts.enable {
      sops.secrets.nextcloud_pass = {
        sopsFile = opts.secretsFile;
        format = "binary";
        mode = "444";
      };

      nix-tun.storage.persist.subvolumes."nextcloud".directories = {
        "/postgres" = {
          owner = "${builtins.toString config.containers.nextcloud.config.users.users.postgres.uid}";
          mode = "0700";
        };
      };

      teenix.services.traefik.services."nextcloud" = {
        router.rule = "Host(`${opts.hostname}`)";
        servers = [ "http://${config.containers.nextcloud.config.networking.hostName}" ];
      };

      containers.nextcloud = {
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.100.10";
        localAddress = "192.168.100.11";
        bindMounts = {
          "secret" = {
            hostPath = config.sops.secrets.nextcloud_pass.path;
            mountPoint = config.sops.secrets.nextcloud_pass.path;
          };
          "db" = {
            hostPath = "${config.nix-tun.storage.persist.path}/nextcloud/postgres";
            mountPoint = "/var/lib/postgres";
            isReadOnly = false;
          };
        };

        specialArgs = {
          inherit inputs pkgs;
          host-config = config;
        };

        config =
          import ./container.nix;
      };
    };
}
