{ lib
, config
, ...
}: {
  options.teenix.services.keycloak = {
    enable = lib.mkEnableOption "setup nextcloud";
    secretsFile = lib.mkOption {
      type = lib.types.path;
      description = "path to the sops secret file for the adminPass";
    };

  };
  config =
    let
      opts = config.teenix.services.keycloak;
    in
    lib.mkIf opts.enable {
      sops.secrets.keycloak = {
        sopsFile = opts.secretsFile;
        format = "binary";
        mode = "444";
      };

      containers.keycloak = {
        environment.noXlibs = false;

        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.101.10";
        localAddress = "192.168.101.11";

        config = { pkgs, lib, ... }: {
          services.postgresql.enable = true;

          services.keycloak = {
            enable = true;
            settings = {
              hostname = "http://192.168.101.11";
              http-enabled = true;
              proxy = "passthrough";
              hostname-strict-https = false;
            };
            database = {
              passwordFile = config.sops.secrets.keycloak.path;

              type = "postgresql";
              createLocally = true;

              username = "keycloak";
            };
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
