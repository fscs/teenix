{ lib
, config
, pkgs
, inputs
, ...
}: {
  options.teenix.services.pretix = {
    enable = lib.mkEnableOption "setup pretix";
    hostname = lib.mkOption {
      type = lib.types.str;
    };
    email = lib.mkOption {
      type = lib.types.str;
    };
  };

  config =
    let
      opts = config.teenix.services.pretix;
    in
    lib.mkIf opts.enable {
      teenix.services.traefik.services."pretix" = {
        router.rule = "Host(`${opts.hostname}`)";
        servers = [ "http://${config.containers.pretix.config.networking.hostName}" ];
        healthCheck.enable = true;
      };

      nix-tun.storage.persist.subvolumes."pretix".directories = {
        "/postgres" = {
          owner = "${builtins.toString config.containers.pretix.config.users.users.postgres.uid}";
          mode = "0700";
        };
      };

      containers.pretix = {
        ephemeral = true;
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.108.10";
        localAddress = "192.168.108.11";
        bindMounts = {
          "db" = {
            hostPath = "${config.nix-tun.storage.persist.path}/pretix/postgres";
            mountPoint = "/var/lib/postgresql";
            isReadOnly = false;
          };
        };

        specialArgs = {
          inherit inputs pkgs;
          host-config = config;
        };

        config = import ./container.nix;
      };
    };
}
