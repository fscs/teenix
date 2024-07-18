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
    db_hostPath = lib.mkOption {
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
        bindMounts =
          {
            "secret" =
              {
                hostPath = config.sops.secrets.fscs-intern-bot.path;
                mountPoint = config.sops.secrets.fscs-intern-bot.path;
              };
            "db" = {
              hostPath = opts.db_hostPath;
              mountPoint = "/home/fscs-hhu/db";
              isReadOnly = false;
            };
          };

        config = { lib, ... }: {
          users.users.fscs-hhu = {
            home = "/home/fscs-hhu";
            group = "users";
            isNormalUser = true;
          };
          environment.systemPackages = [
            inputs.fscs-intern-bot.packages."${pkgs.stdenv.hostPlatform.system}".serve
          ];
          systemd.services.fscs-intern-bot = {
            description = "Serve FSCS intern bot";
            after = [ "network.target" ];
            serviceConfig = {
              EnvironmentFile = config.sops.secrets.fscs-intern-bot.path;
              Type = "exec";
              User = "fscs-hhu";
              WorkingDirectory = "/home/fscs-hhu";
              ExecStart = "${inputs.fscs-intern-bot.packages."${pkgs.stdenv.hostPlatform.system}".serve}/bin/serve";
              Restart = "always";
              RestartSec = 5;
            };
            wantedBy = [ "multi-user.target" ];
          };
          system.stateVersion = "23.11";

          services.resolved.enable = true;
        };
      };
    };
}
