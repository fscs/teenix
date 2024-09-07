{ lib
, config
, inputs
, pkgs
, ...
}: {
  options.teenix.services.fscshhude = {
    enable = lib.mkEnableOption "setup fscshhude";
    secretsFile = lib.mkOption {
      type = lib.types.path;
      description = "path to the sops secret file for the fscshhude website Server";
    };
    hostname = lib.mkOption {
      type = lib.types.str;
    };
  };

  config =
    let
      opts = config.teenix.services.fscshhude;
    in
    lib.mkIf opts.enable {
      sops.secrets.fscshhude = {
        sopsFile = opts.secretsFile;
        format = "binary";
        mode = "444";
      };

      nix-tun.storage.persist.subvolumes."fscshhude".directories = {
        "/db" = {
          owner = "${builtins.toString config.containers.fscshhude.config.users.users.fscs-website.uid}";
          mode = "0700";
        };
      };

      teenix.services.traefik.services."fscshhude" = {
        router.rule = "Host(`${opts.hostname}`)";
        servers = [ "http://${config.containers.fscshhude.config.networking.hostName}:8080" ];
        healthCheck = true;
      };

      containers.fscshhude = {
        ephemeral = true;
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.103.10";
        localAddress = "192.168.103.11";
        bindMounts = {
          "secret" = {
            hostPath = config.sops.secrets.fscshhude.path;
            mountPoint = config.sops.secrets.fscshhude.path;
          };
          "db" = {
            hostPath = "${config.nix-tun.storage.persist.path}/fscshhude/db";
            mountPoint = "/home/fscs-website/db";
            isReadOnly = false;
          };
        };

        specialArgs = {
          inherit inputs pkgs;
          host-config = config;
        };

        config = import ./container.nix;
      };
    };
}
