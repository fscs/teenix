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
      sops.secrets.keycloak_pass = {
        sopsFile = opts.secretsFile;
        format = "binary";
        mode = "444";
      };

      containers.keycloak = {
        ephemeral = true;

        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.101.10";
        localAddress = "192.168.101.11";

        bindMounts =
          {
            "secret" =
              {
                hostPath = config.sops.secrets.keycloak_pass.path;
                mountPoint = config.sops.secrets.keycloak_pass.path;
              };
          };

        config = { pkgs, lib, ... }: {

          services.keycloak = {
            enable = true;
            settings = {
              hostname = "192.168.101.11";
              http-enabled = true;
              hostname-strict-https = false;
              hostname-strict-backchannel = true;
            };
            database = {
              passwordFile = config.sops.secrets.keycloak_pass.path;

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
