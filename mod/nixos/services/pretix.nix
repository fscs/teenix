{ lib
, config
, pkgs
, ...
}: {
  options.teenix.services.pretix = {
    enable = lib.mkEnableOption "setup pretix";
    hostname = lib.mkOption {
      type = lib.types.str;
      description = "hostname";
    };
    email = lib.mkOption {
      type = lib.types.str;
      description = "email";
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
        bindMounts =
          {
            "db" = {
              hostPath = "${config.nix-tun.storage.persist.path}/pretix/postgres";
              mountPoint = "/var/lib/postgres";
              isReadOnly = false;
            };
          };
        config = {
          networking = {
            hostName = "pretix";
          };

          services.pretix = {
            enable = true;
            package = pkgs.stable.pretix;
            database.createLocally = true;
            nginx.domain = opts.hostname;
            settings = {
              mail.from = "${opts.email}";
              pretix = {
                instance_name = "${opts.hostname}";
                url = "https://${opts.hostname}";
              };
            };
          };
        };
      };
    };
}

