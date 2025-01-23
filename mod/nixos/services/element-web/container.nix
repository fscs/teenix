{
  pkgs,
  host-config,
  ...
}:
let
  opts = host-config.teenix.services.element-web;
  element =
    let
      conf = {
        default_server_config = {
          "m.homeserver" = {
            base_url = "https://${opts.matrixUrl}";
            server_name = "${opts.matrixUrl}";
          };
          "m.identity_server".base_url = "https://sydent.inphima.de";
        };
      };
    in
    pkgs.element-web.override { inherit conf; };
in
{
  systemd.services.element-serve = {
    description = "Serve element";
    after = [ "network.target" ];
    serviceConfig = {
      Type = "exec";
      ExecStart = "${pkgs.caddy}/bin/caddy file-server -r ${element} --listen :80";
      Restart = "always";
      RestartSec = 5;
    };
    wantedBy = [ "multi-user.target" ];
  };

  system.stateVersion = "23.11";
}
