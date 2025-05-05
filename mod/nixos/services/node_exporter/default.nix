{
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [ ./meta.nix ];

  options.teenix.services.node_exporter = {
    enable = lib.mkEnableOption "node_exporter";
  };

  config =
    let
      opts = config.teenix.services.node_exporter;
    in
    lib.mkIf opts.enable {
      users.groups.node_exporter = { };
      users.users.node_exporter = {
        isSystemUser = true;
        group = "node_exporter";
      };

      systemd.services.node_exporter = {
        description = "Start node exporter";
        after = [ "network.target" ];
        path = [ pkgs.bash ];
        serviceConfig = {
          Type = "exec";
          User = "node_exporter";
          WorkingDirectory = "/var/lib/node_exporter";
          StateDirectory = "node_exporter";
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
