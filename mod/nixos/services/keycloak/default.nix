{ lib
, config
, inputs
, pkgs
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
        "/mysql" = {
          owner = "${builtins.toString config.containers.keycloak.config.users.users.mysql.uid}";
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
          "resolv" = {
            hostPath = "/etc/resolv.conf";
            mountPoint = "/etc/resolv.conf";
          };
          "db" = {
            hostPath = "${config.nix-tun.storage.persist.path}/keycloak/mysql";
            mountPoint = "/var/lib/mysql";
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
