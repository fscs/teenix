{ lib
, config
, pkgs
, inputs
, ...
}: {
  options.teenix.services.passbolt =
    let
      t = lib.types;
    in
    {
      enable = lib.mkEnableOption "setup passbolt";
      hostname = lib.mkOption {
        type = t.str;
      };
      envFile = lib.mkOption {
        type = t.path;
      };
      mariaEnvFile = lib.mkOption {
        type = t.path;
      };
    };

  config =
    let
      opts = config.teenix.services.passbolt;
    in
    lib.mkIf opts.enable {
      sops.secrets.passbolt = {
        sopsFile = opts.envFile;
        format = "binary";
        mode = "444";
      };

      sops.secrets.passbolt_mariadb = {
        sopsFile = opts.mariaEnvFile;
        format = "binary";
        mode = "444";
      };

      nix-tun.storage.persist.subvolumes."passbolt".directories = {
        "/postgres" = {
          owner = "1000";
          mode = "0777";
        };
        "/env" = {
          owner = "1000";
          mode = "0777";
        };
      };

      teenix.services.traefik.services."passbolt" = {
        router.rule = "Host(`${opts.hostname}`)";
        servers = [ "http://${config.containers.passbolt.config.networking.hostName}:8080" ];
      };

      containers.passbolt = {
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.113.10";
        localAddress = "192.168.113.11";
        bindMounts = {
          "db" = {
            hostPath = "${config.nix-tun.storage.persist.path}/passbolt/postgres";
            mountPoint = "/var/lib/postgres";
            isReadOnly = false;
          };
          "env" = {
            hostPath = config.sops.secrets.passbolt.path;
            mountPoint = config.sops.secrets.passbolt.path;
          };
          "maria_env" = {
            hostPath = config.sops.secrets.passbolt_mariadb.path;
            mountPoint = config.sops.secrets.passbolt_mariadb.path;
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
