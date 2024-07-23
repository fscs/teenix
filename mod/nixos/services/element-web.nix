{ lib
, config
, inputs
, pkgs
, ...
}: {
  options.teenix.services.element-web = {
    enable = lib.mkEnableOption "setup element-web";
    hostname = lib.mkOption {
      type = lib.types.str;
      description = "hostname";
    };
  };
  config =
    let
      opts = config.teenix.services.element-web;
    in
    lib.mkIf opts.enable {

      teenix.services.traefik.services."element-web" = {
        router.rule = "Host(`${opts.hostname}`)";
        servers = [ "http://${config.containers.element-web.config.networking.hostName}:8000" ];
      };

      containers.element-web = {
        ephemeral = true;
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.107.10";
        localAddress = "192.168.107.11";

        config = { config, lib, ... }: {
          networking.hostName = "element-web";
          systemd.services.fscs-website-serve =
            let
              conf = {
                default_server_config = {
                  m.homeserver = {
                    base_url = "https://${opts.hostname}";
                  };
                  m.identity_server = {
                    base_url = "https://vector.im";
                  };
                };
              };
            in
            pkgs.element-web.override { inherit conf; } {
              description = "Serve element";
              after = [ "network.target" ];
              serviceConfig = {
                Type = "exec";
                ExecStart = "${pkgs.simple-http-server}/bin/simple-http-server ${pkgs.element-web} --index";
                Restart = "always";
                RestartSec = 5;
              };
              wantedBy = [ "multi-user.target" ];
            };
          system.stateVersion = "23.11";

          networking = {
            firewall = {
              enable = true;
              allowedTCPPorts = [ 8000 ];
            };
            # Use systemd-resolved inside the container
            # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
            useHostResolvConf = lib.mkForce false;
          };
        };
      };
    };
}
