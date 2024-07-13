{ lib
, config
, ...
}: {
  options.teenix.services.traefik = {
    enable = lib.mkEnableOption "setup traefik";
    configFile = lib.mkOption {
      type = lib.types.path;
      description = "path to the config file for traefik";
    };

  };
  config =
    let
      opts = config.teenix.services.traefik;
    in
    lib.mkIf opts.enable {
      containers.traefik = {
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.102.10";
        localAddress = "192.168.102.11";
        bindMounts =
          {
            "secret" =
              {
                hostPath = opts.configfile;
                mountPoint = /run/traefik/config;
              };
          };

        config = { pkgs, lib, ... }: {
          services.traefik = {
            enable = true;
            staticConfigFile = /run/traefik/config;
          };
          system.stateVersion = "23.11";

          networking = {
            firewall = {
              enable = true;
              allowedTCPPorts = [ 80 ];
            };
            # Use systemd-resolved inside the container
            # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
            useHostResolvConf = lib.mkForce false;
          };

          services.resolved.enable = true;
        };
      };
    };
}
