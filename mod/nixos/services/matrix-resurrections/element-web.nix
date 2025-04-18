{
  lib,
  pkgs,
  host-config,
  ...
}:
let
  element =
    let
      conf = {
        default_server_config = {
          "m.homeserver" = {
            base_url = "https://${host-config.services.matrix.hostnames.homeserver}";
            server_name = host-config.services.matrix.hostnames.homeserver;
          };
          "m.identity_server".base_url = host-config.services.matrix.hostnames.sydent;
        };
      };
    in
    pkgs.element-web.override { inherit conf; };
in
{
  systemd.services.element-web-serve = {
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
