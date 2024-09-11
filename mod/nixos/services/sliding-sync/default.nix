{ lib
, config
, inputs
, pkgs
, ...
}: {
  options.teenix.services.sliding-sync = {
    enable = lib.mkEnableOption "setup sliding-sync";
    hostname = lib.mkOption {
      type = lib.types.str;
    };
    envFile = lib.mkOption {
      type = lib.types.path;
    };
  };

  config =
    let
      opts = config.teenix.services.sliding-sync;
    in
    lib.mkIf opts.enable {
      sops.secrets.sliding-sync = {
        sopsFile = opts.envFile;
        format = "binary";
        mode = "444";
      };

      nix-tun.storage.persist.subvolumes."sliding-sync".directories = {
        "/db" = {
          owner = "1000";
          mode = "0700";
        };
      };

      teenix.services.traefik.services."sliding-sync" = {
        router.rule = "Host(`${opts.hostname}`)";
        servers = [ "http://${config.containers.sliding-sync.config.networking.hostName}:8009" ];
      };

      containers.sliding-sync = {
        ephemeral = true;
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.112.10";
        localAddress = "192.168.112.11";
        bindMounts = {
          "resolv" = {
            hostPath = "/etc/resolv.conf";
            mountPoint = "/etc/resolv.conf";
          };
          "env" = {
            hostPath = config.sops.secrets.sliding-sync.path;
            mountPoint = config.sops.secrets.sliding-sync.path;
          };
          "db" = {
            hostPath = "${config.nix-tun.storage.persist.path}/sliding-sync/db";
            mountPoint = "/var/lib/postgres";
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
