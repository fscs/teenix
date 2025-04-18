{
  lib,
  pkgs,
  host-config,
  ...
}:
let
  element = pkgs.element-web.override {
    conf = {
      default_server_config = {
        "m.homeserver" = {
          base_url = "https://${host-config.teenix.services.matrix.hostnames.homeserver}";
          server_name = host-config.teenix.services.matrix.hostnames.homeserver;
        };
        "m.identity_server".base_url = host-config.teenix.services.matrix.hostnames.sydent;
      };
    };
  };
in
{
  systemd.services.element-web = {
    description = "Serve element-web";
    after = [ "network.target" ];
    serviceConfig = {
      Type = "exec";
      ExecStart = "${lib.getExe pkgs.caddy} file-server -r ${element} --listen :8000";
      Restart = "always";
      RestartSec = 5;
    };
    wantedBy = [ "multi-user.target" ];
  };
}
