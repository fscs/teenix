{ lib
, config
, inputs
, pkgs
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
        router =
          {
            rule = "Host(`${opts.hostname}`)";
            priority = 10;
          };
        servers = [ "http://${config.containers.authentik.config.networking.hostName}" ];
      };

      teenix.services.traefik.services."authentik_auth" = {
        router = {
          rule = "Host(`${opts.hostname}`) && PathPrefix(`/outpost.goauthentik.io/`)";
          priority = 15;
        };
        servers = [ "http://${config.containers.authentik.config.networking.hostName}:9000/outpost.goauthentik.io" ];
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
          "resolv" = {
            hostPath = "/etc/resolv.conf";
            mountPoint = "/etc/resolv.conf";
          };
          "db" = {
            hostPath = "${config.nix-tun.storage.persist.path}/authentik/postgres";
            mountPoint = "/var/lib/postgresql";
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
