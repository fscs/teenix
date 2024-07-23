{ lib
, config
, inputs
, pkgs
, ...
}: {
  config =
    let
      opts = config.teenix.services.matrix;
    in
    lib.mkIf opts.enable {

      containers.element-web = {
        ephemeral = true;
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.106.10";
        localAddress = "192.168.106.11";

        config = { config, lib, ... }: {
          systemd.services.fscs-website-serve = {
            description = "Serve element";
            after = [ "network.target" ];
            serviceConfig = {
              Type = "exec";
              ExecStart = "${pkgs.simple-http-server}/bin/simple-http-server ${pkgs.element-web}";
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
