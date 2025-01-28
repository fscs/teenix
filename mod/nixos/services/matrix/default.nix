{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
{
  options.teenix.services.matrix = {
    enable = lib.mkEnableOption "setup inphimatrix";
    servername = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Servername for matrix. The Matrix Host will be matrix.servername, except for .well-known files";
    };

    masSecrets = lib.mkOption {
      type = lib.types.path;
    };
    hookshotSecrets = lib.mkOption {
      type = lib.types.path;
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

      sops.secrets.masSecrets = {
        sopsFile = opts.masSecrets;
        format = "binary";
        mode = "444";
      };

      sops.secrets.matrix_env = {
        sopsFile = opts.configFile;
        format = "binary";
        mode = "444";
      };

      sops.secrets.matrix-hookshot = {
        sopsFile = opts.hookshotSecrets;
        format = "binary";
        mode = "444";
      };

      nix-tun.storage.persist.subvolumes."inphimatrix".directories = {
        "/postgres" = {
          owner = "${builtins.toString config.containers.inphimatrix.config.users.users.postgres.uid}";
          mode = "0700";
        };
        "/data" = {
          owner = "${builtins.toString config.containers.inphimatrix.config.users.users.matrix-synapse.uid}";
          mode = "0700";
        };
        "/auth" = {
          owner = "${builtins.toString config.containers.inphimatrix.config.users.users.matrix-authentication-service.uid}";
          mode = "0700";
        };
      };

      teenix.services.traefik.services.inphimatrix = {
        router = {
          rule = "Host(`matrix.${opts.servername}`) || (Host(`${opts.servername}`) && (PathPrefix(`/_matrix`) || PathPrefix(`/_synapse`) || Path(`/.well-known/matrix/server`) || Path(`/.well-known/matrix/client`)))";
          priority = 10;
        };
        healthCheck = {
          enable = true;
          path = "_matrix/static/";
        };
        servers = [ "http://${config.containers.inphimatrix.localAddress}:8008" ];
      };

      teenix.services.traefik.services.inphimatrix_auth = {
        router = {
          rule = "Host(`matrixauth.${opts.servername}`) || (( Host(`matrix.${opts.servername}`) || Host(`${opts.servername}`)) && PathRegexp(`^/_matrix/client/.*/(login|logout|refresh)`) )";
        };
        healthCheck = {
          enable = true;
        };
        servers = [ "http://${config.containers.inphimatrix.localAddress}:8080" ];
      };

      teenix.services.traefik.services.matrix-hookshot = {
        router.rule = "Host(`hookshot.${opts.servername}`)";
        servers = [ "http://${config.containers.inphimatrix.localAddress}:9000" ];
      };

      containers.inphimatrix = {
        ephemeral = true;
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.105.10";
        localAddress = "192.168.105.11";
        bindMounts = {
          "resolv" = {
            hostPath = "/etc/resolv.conf";
            mountPoint = "/etc/resolv.conf";
          };
          "secret" = {
            hostPath = config.sops.secrets.matrix_pass.path;
            mountPoint = config.sops.secrets.matrix_pass.path;
          };
          "masSecrets" = {
            hostPath = config.sops.secrets.masSecrets.path;
            mountPoint = config.sops.secrets.masSecrets.path;
          };
          "hookshotSecrets" = {
            hostPath = config.sops.secrets.matrix-hookshot.path;
            mountPoint = config.sops.secrets.matrix-hookshot.path;
          };
          "env" = {
            hostPath = config.sops.secrets.matrix_env.path;
            mountPoint = config.sops.secrets.matrix_env.path;
          };
          "synapse" = {
            hostPath = "${config.nix-tun.storage.persist.path}/inphimatrix/data";
            mountPoint = "/var/lib/matrix-synapse";
            isReadOnly = false;
          };
          "auth" = {
            hostPath = "${config.nix-tun.storage.persist.path}/inphimatrix/auth";
            mountPoint = "/var/lib/matrix-auth";
            isReadOnly = false;
          };
          "media_store" = {
            hostPath = "/mnt/netapp/inphimatrix/media_store";
            mountPoint = "/var/lib/matrix-synapse/media_store";
            isReadOnly = false;
          };
          "db" = {
            hostPath = "${config.nix-tun.storage.persist.path}/inphimatrix/postgres";
            mountPoint = "/var/lib/postgres";
            isReadOnly = false;
          };
        };

        specialArgs = {
          inherit inputs;
          host-config = config;
        };

        config = import ./container.nix;
      };
    };
}
