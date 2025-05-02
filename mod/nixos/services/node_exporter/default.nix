{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.teenix.services.node_exporter = {
    enable = lib.mkEnableOption "setup node_exporter";
  };

  config =
    let
      opts = config.teenix.services.node_exporter;
    in
    lib.mkIf opts.enable {
      users.users.node_exporter = {
        uid = 1033;
        home = "/home/node_exporter";
        group = "users";
        shell = pkgs.bash;
        isNormalUser = true;
      };

      systemd.services.node_exporter-serve = {
        description = "Start node exporter";
        after = [ "network.target" ];
        path = [ pkgs.bash ];
        serviceConfig = {
          Type = "exec";
          User = "node_exporter";
          WorkingDirectory = "/home/node_exporter";
          ExecStart = "${pkgs.prometheus-node-exporter}/bin/node_exporter";
          Restart = "always";
          RestartSec = 5;
        };
        wantedBy = [ "multi-user.target" ];
      };
      networking.firewall = {
        allowedTCPPorts = [ 9100 ];
      };
    };
}
