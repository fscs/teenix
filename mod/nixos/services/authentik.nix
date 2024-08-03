{ lib
, config
, inputs
, ...
}: {
  options.teenix.services.authentik = {
    enable = lib.mkEnableOption "setup authentik";
    hostname = lib.mkOption {
      type = lib.types.str;
    };
    envFile = lib.mkOption {
      type = lib.types.path;
      description = "path to the sops secret file for the fscshhude website Server";
    };
  };

  config =
    let
      opts = config.teenix.services.authentik;
    in
    lib.mkIf opts.enable {
      sops.secrets.authentik_env = {
        sopsFile = opts.envFile;
        format = "binary";
        mode = "444";
      };

      nix-tun.storage.persist.subvolumes."authentik".directories = {
        "/postgres" = {
          owner = "${builtins.toString config.containers.authentik.config.users.users.postgres.uid}";
          mode = "0700";
        };
      };

      teenix.services.traefik.services."authentik" = {
        router.rule = "Host(`${opts.hostname}`)";
        servers = [ "http://${config.containers.authentik.config.networking.hostName}" ];
      };

      containers.authentik = {
        ephemeral = true;
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.111.10";
        localAddress = "192.168.111.11";

        bindMounts = {
          "secret" = {
            hostPath = config.sops.secrets.authentik_env.path;
            mountPoint = config.sops.secrets.authentik_env.path;
          };
          "db" = {
            hostPath = "${config.nix-tun.storage.persist.path}/authentik/postgres";
            mountPoint = "/var/lib/postgresql";
            isReadOnly = false;
          };
        };

        config =
          { pkgs
          , lib
          , ...
          }: {
            imports = [
              inputs.authentik-nix.nixosModules.default
            ];

            networking.hostName = "authentik";

            services.authentik = {
              enable = true;
              environmentFile = config.sops.secrets.authentik_env.path;
              createDatabase = true;
              settings = {
                email = {
                  host = "mail.hhu.de";
                  port = 587;
                  username = "fscs";
                  use_tls = true;
                  use_ssl = false;
                  from = "fscs@hhu.de";
                };
                disable_startup_analytics = true;
                avatars = "initials";
              };
              nginx = {
                enable = true;
                enableACME = false;
                host = "localhost";
              };
            };

            system.stateVersion = "23.11";

            networking = {
              firewall = {
                enable = true;
                allowedTCPPorts = [ 80 9443 ];
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
