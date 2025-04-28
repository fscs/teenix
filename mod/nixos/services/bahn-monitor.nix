{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  options.teenix.services.bahn-monitor = {
    enable = lib.mkEnableOption "setup a train monitor server";
    hostname = lib.teenix.mkHostnameOption;
  };

  config = lib.mkIf config.teenix.services.bahn-monitor.enable {
    teenix.services.traefik.services.bahn = {
      router.rule = "Host(`${config.teenix.services.bahn-monitor.hostname}`)";
      servers = [ "http://${config.containers.bahn-monitor.localAddress}:8080" ];
    };

    teenix.containers.bahn-monitor = {
      config = {
        users.users.bahn-monitor = {
          uid = 1000;
          isNormalUser = true;
        };

        systemd.services.bahn-monitor = {
          description = "Serve discord intern bot";
          after = [ "network.target" ];
          serviceConfig = {
            Type = "exec";
            User = "bahn-monitor";
            ExecStart = lib.getExe inputs.bahn.packages."${pkgs.stdenv.system}".default;
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
