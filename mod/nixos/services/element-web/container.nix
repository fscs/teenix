{ pkgs
, lib
, host-config
, ...
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
          "m.identity_server".base_url = "https://vector.im";
        };
      };
    in
    pkgs.unstable.element-web.override { inherit conf; };
in
{
  networking.hostName = "element-web";

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

  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 80 ];
    };
    # Use systemd-resolved inside the container
    # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
    useHostResolvConf = lib.mkForce false;
  };

  system.stateVersion = "23.11";
}
