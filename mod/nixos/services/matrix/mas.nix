{ pkgs, pkgs-unstable, lib, config, ... }: {

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
    users.users."matrix-authentication-service" = {
      uid = 1444;
      group = "users";
      isSystemUser = true;
    };
    systemd.services."mautrix-authentication-service" = {
      description = "Matrix Authentication Service";
      after = [ "network.target" ];
      path = [ pkgs.bash ];
      script = "${pkgs-unstable.matrix-authentication-service}/bin/mas-cli server --config=${config.teenix.services.mas.secretFile} --config=${pkgs.writeText "config.yaml" (lib.generators.toYAML {} config.teenix.services.mas.settings)}";
      serviceConfig = {
        User = "matrix-authentication-service";
        WorkingDirectory = "/var/lib/matrix-auth";
        Restart = "always";
        RestartSec = 5;
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
