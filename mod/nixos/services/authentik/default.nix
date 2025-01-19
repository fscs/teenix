{ lib
, config
, inputs
, pkgs
, ...
}:
{
  options.teenix.services.authentik = {
    enable = lib.mkEnableOption "setup authentik";
    hostname = lib.teenix.mkHostnameOption;
    secretsFile = lib.teenix.mkSecretsFileOption "authentik";
  };

  config =
    let
      opts = config.teenix.services.authentik;
    in
    lib.mkIf opts.enable {
      sops.secrets.authentik_env = {
        sopsFile = opts.secretsFile;
        format = "binary";
        mode = "444";
      };

      # setup authentik binary cache 
      nix.settings = {
        substituters = [
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
      };

      nix-tun.storage.persist.subvolumes."authentik".directories = {
        "/postgres" = {
          owner = "${builtins.toString config.containers.authentik.config.users.users.postgres.uid}";
          mode = "0700";
        };
      };

      teenix.services.traefik.services."authentik" = {
        router = {
          rule = "Host(`${opts.hostname}`)";
          priority = 10;
        };
        servers = [ "http://${config.containers.authentik.config.networking.hostName}" ];
        healthCheck.enable = true;
      };

      teenix.services.traefik.services."authentik_auth" = {
        router = {
          rule = "Host(`${opts.hostname}`) && PathPrefix(`/outpost.goauthentik.io/`)";
          priority = 15;
        };
        servers = [
          "http://${config.containers.authentik.config.networking.hostName}:9000/outpost.goauthentik.io"
        ];
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
          inherit inputs;
          host-config = config;
        };

        config = import ./container.nix;
      };
    };
}
