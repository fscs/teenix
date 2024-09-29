{ pkgs, lib, config, ... }: {

  options.teenix.services.mas = {
    enable = lib.mkEnableOption "Enable Matrix Authentication ServiceS";
    secretFile = lib.mkOption {
      type = lib.types.str;
    };
    settings = lib.mkOption {
      type = lib.types.attrs;
    };
  };

  config = lib.mkIf config.teenix.services.mas.enable {
    systemd.services."mautrix-authentication-service" = {
      description = "Matrix Authentication Service";
      after = [ "network.target" ];
      path = [ pkgs.bash ];
      script = "${pkgs.matrix-authentication-service}/bin/mas-cli";
      scriptArgs = "server --config=${config.teenix.services.mas.secretFile} --config=${builtins.toFile "config.yaml" (lib.generators.toYAML {} config.teenix.services.mas.settings)}";
      serviceConfig = {
        WorkingDirectory = "/var/lib/matrix-auth";
        Restart = "always";
        RestartSec = 5;
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
