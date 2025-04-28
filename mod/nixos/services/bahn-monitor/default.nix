{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  options.teenix.services.bahn-monitor = {
    enable = lib.mkEnableOption "fscs-monitor-plus, a train monitoring service";
    hostname = lib.teenix.mkHostnameOption;
  };

  config = lib.mkIf config.teenix.services.bahn-monitor.enable {
    teenix.services.traefik.services.bahn-monitor = {
      router.rule = "Host(`${config.teenix.services.bahn-monitor.hostname}`)";
      servers = [ "http://${config.containers.bahn-monitor.localAddress}:8080" ];
    };

    teenix.containers.bahn-monitor = {
      config = {
        systemd.services.bahn-monitor = {
          after = [ "network.target" ];
          serviceConfig = {
            Type = "exec";
            DynamicUser = true;
            ExecStart = lib.getExe inputs.fscs-monitor-plus.packages."${pkgs.stdenv.system}".default;
            Restart = "always";
            RestartSec = 5;
          };
          wantedBy = [ "multi-user.target" ];
        };

        system.stateVersion = "23.11";
      };

      networking = {
        useResolvConf = true;
        ports.tcp = [ 8080 ];
      };
    };
  };
}
