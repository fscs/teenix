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
            hostPath = opts.dbHostPath;
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
