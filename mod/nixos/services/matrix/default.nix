{ lib
, config
, inputs
, pkgs
, ...
}: {
  options.teenix.services.matrix = {
    enable = lib.mkEnableOption "setup inphimatrix";
    servername = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Servername for matrix. The Matrix Host will be matrix.servername, except for .well-known files";
    };
    secretsFile = lib.mkOption {
      type = lib.types.path;
    };
    configFile = lib.mkOption {
      type = lib.types.path;
    };
  };

  config =
    let
      opts = config.teenix.services.matrix;
    in
    lib.mkIf opts.enable {
      sops.secrets.matrix_pass = {
        sopsFile = opts.secretsFile;
        format = "binary";
        mode = "444";
      };

      sops.secrets.matrix_env = {
        sopsFile = opts.configFile;
        format = "binary";
        mode = "444";
      };

      nix-tun.storage.persist.subvolumes."inphimatrix".directories = {
        "/postgres" = {
          owner = "${builtins.toString config.containers.inphimatrix.config.users.users.postgres.uid}";
          mode = "0700";
        };
      };

      teenix.services.traefik.services.inphimatrix = {
        router.rule = "Host(`matrix.${opts.servername}`) || (Host(`${opts.servername}`) && (Path(`/_matrix/{name:.*}`) || Path(`/_synapse/{name:.*}`) || Path(`/.well-known/matrix/server`) || Path(`/.well-known/matrix/client`)))";
        servers = [ "http://${config.containers.inphimatrix.config.networking.hostName}:8008" ];
        healthCheck = true;
      };

      containers.inphimatrix = {
        ephemeral = true;
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.105.10";
        localAddress = "192.168.105.11";
        bindMounts = {
          "secret" = {
            hostPath = config.sops.secrets.matrix_pass.path;
            mountPoint = config.sops.secrets.matrix_pass.path;
          };
          "env" = {
            hostPath = config.sops.secrets.matrix_env.path;
            mountPoint = config.sops.secrets.matrix_env.path;
          };
          "db" = {
            hostPath = "${config.nix-tun.storage.persist.path}/inphimatrix/postgres";
            mountPoint = "/var/lib/postgres";
            isReadOnly = false;
          };
        };

        specialArgs = {
          inherit inputs pkgs;
          host-config = config;
        };

        config =
          import ./container.nix;
      };
    };
}
