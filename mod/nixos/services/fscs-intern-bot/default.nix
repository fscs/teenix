{ lib
, config
, inputs
, pkgs
, ...
}: {
  options.teenix.services.fscs-intern-bot = {
    enable = lib.mkEnableOption "setup fscs-intern-bot";
    secretsFile = lib.mkOption {
      type = lib.types.path;
      description = "path to the sops secret file for the fscs-intern-bot";
    };
    dbHostPath = lib.mkOption {
      type = lib.types.str;
    };
  };

  config =
    let
      opts = config.teenix.services.fscs-intern-bot;
    in
    lib.mkIf opts.enable {
      sops.secrets.fscs-intern-bot = {
        sopsFile = opts.secretsFile;
        format = "binary";
        mode = "444";
      };

      nix-tun.storage.persist.subvolumes."fscs-intern-bot".directories = {
        "/postgres" = {
          owner = "${builtins.toString config.containers.fscs-intern-bot.config.users.users.fscs-hhu.uid}";
          mode = "0700";
        };
      };

      containers.fscs-intern-bot = {
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.103.10";
        localAddress = "192.168.103.11";
        bindMounts = {
          "secret" = {
            hostPath = config.sops.secrets.fscs-intern-bot.path;
            mountPoint = config.sops.secrets.fscs-intern-bot.path;
          };
          "db" = {
            hostPath = "${config.nix-tun.storage.persist.path}/fscs-intern-bot/postgres";
            mountPoint = "/home/fscs-hhu/db";
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
