{ lib
, config
, ...
}: {
  options.teenix.services.keycloak = {
    enable = lib.mkEnableOption "setup nextcloud";
    hostname = lib.mkOption {
      type = lib.types.str;
    };
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

      nix-tun.storage.persist.subvolumes."keycloak".directories = {
        "/postgres" = {
          owner = "${builtins.toString config.containers.keycloak.config.users.users.postgres.uid}";
          mode = "0700";
        };
      };

      teenix.services.traefik.services."keycloak" = {
        router.rule = "Host(`${opts.hostname}`)";
        servers = [ "http://${config.containers.keycloak.config.networking.hostName}" ];
        healthCheck = true;
      };

      containers.keycloak = {
        ephemeral = true;
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.101.10";
        localAddress = "192.168.101.11";

        bindMounts = {
          "secret" = {
            hostPath = config.sops.secrets.keycloak_pass.path;
            mountPoint = config.sops.secrets.keycloak_pass.path;
          };
          "db" = {
            hostPath = "${config.nix-tun.storage.persist.path}/keycloak/postgres";
            mountPoint = "/var/lib/postgres";
            isReadOnly = false;
          };
        };

        config =
          { pkgs
          , lib
          , ...
          }: {
            services.keycloak = {
              enable = true;
              settings = {
                hostname = opts.hostname;
                proxy = "edge";
                http-enabled = true;
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
