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
        ephemeral = true;
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.102.10";
        localAddress = "192.168.102.11";
        bindMounts =
          {
            "config" =
              {
                hostPath = "/home/felix/.dotfiles/config/traefik/config.yml";
                mountPoint = "/etc/traefik/config.yml";
                isReadOnly = false;
              };
            "dynamic" =
              {
                hostPath = "/home/felix/.dotfiles/config/traefik/dynamic";
                mountPoint = "/dynamic";
                isReadOnly = false;
              };
          };

        config = { pkgs, lib, ... }: {
          services.traefik = {
            enable = true;
            staticConfigFile = "/etc/traefik/config.yml";
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
