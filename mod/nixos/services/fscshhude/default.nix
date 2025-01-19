{ lib
, config
, inputs
, pkgs
, ...
}:
{
  options.teenix.services.fscshhude = {
    enable = lib.mkEnableOption "setup fscshhude";
    secretsFile = lib.teenix.mkSecretsFileOption "fscshhude";
    hostname = lib.teenix.mkHostnameOption;
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

      services.traefik.dynamicConfigOptions = {
        http.routers.fscshhude.tls.certResolver = lib.mkForce "uniintern";
      };

      nix-tun.storage.persist.subvolumes."fscshhude".directories = {
        "/db" = {
          owner = "${builtins.toString config.containers.fscshhude.config.users.users.fscs-website.uid}";
          mode = "0700";
        };
      };

      teenix.services.traefik.services."fscshhude_manage" = {
        router = {
          rule = "Host(`sitzungen.${opts.hostname}`)";
        };
        servers = [ "http://${config.containers.fscshhude.config.networking.hostName}:8090" ];
      };

      teenix.services.traefik.services."fscshhude" = {
        router.rule = "Host(`fscs.hhu.de`) || Host(`fscs.uni-duesseldorf.de`)";
        healthCheck = {
          enable = true;
          path = "/de/";
        };
        servers = [ "http://${config.containers.fscshhude.config.networking.hostName}:8080" ];
      };

      containers.fscshhude = {
        ephemeral = true;
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.103.10";
        localAddress = "192.168.103.11";
        bindMounts = {
          "resolv" = {
            hostPath = "/etc/resolv.conf";
            mountPoint = "/etc/resolv.conf";
          };
          "secret" = {
            hostPath = config.sops.secrets.fscshhude.path;
            mountPoint = config.sops.secrets.fscshhude.path;
          };
          "db" = {
            hostPath = "${config.nix-tun.storage.persist.path}/fscshhude/db";
            mountPoint = "/home/fscs-website/db";
            isReadOnly = false;
          };
          "logs" = {
            hostPath = "/var/log/fscshhude";
            mountPoint = "/var/log/fscshhude";
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
