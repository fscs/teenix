{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
{
  imports = [ ./meta.nix ];

  options.teenix.services.static-files = {
    enable = lib.mkEnableOption "static-files Datenschutz und So";
    hostname = lib.teenix.mkHostnameOption "static-files Datenschutz und So";
  };

  config =
    let
      cfg = config.teenix.services.static-files;
    in
    lib.mkIf cfg.enable {
      teenix.containers.static-files = {
        config = {
          systemd.services.static-files = {
            description = "Serve static-files";
            after = [ "network.target" ];
            path = [ pkgs.bash ];
            serviceConfig = {
              Type = "exec";
              DynamicUser = true;
              ExecStart = "${lib.getExe pkgs.caddy} file-server -r /var/lib/static-files --listen :8080";
              Restart = "always";
              RestartSec = 5;
            };
            wantedBy = [ "multi-user.target" ];
          };

          system.stateVersion = "24.11";
        };

        mounts.data.enable = true;

        networking = {
          useResolvConf = true;
          ports.tcp = [ 8080 ];
        };
      };
    };
}
