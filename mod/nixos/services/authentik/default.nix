{ lib
, config
, ...
}:
{
  options.teenix.services.authentik = {
    enable = lib.mkEnableOption "setup authentik";
    secretsFile = lib.teenix.mkSecretsFileOption "authentik";
    hostname = lib.teenix.mkHostnameOption;
  };

  config =
    let
      opts = config.teenix.services.authentik;
    in
    lib.mkIf opts.enable {
      sops = {
        secrets.authentik-admin-token = {
          sopsFile = opts.secretsFile;
          key = "admin-token";
          mode = "444";
        };

        templates.authentik.content = ''
          AUTHENTIK_SECRET_KEY=${config.sops.placeholder.authentik-admin-token}
        '';
      };

      # setup authentik binary cache
      nix.settings = {
        substituters = [
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
      };

      teenix.services.traefik.services.authentik = {
        router.rule = "Host(`${opts.hostname}`)";
        servers = [ "http://${config.containers.authentik.config.networking.hostName}" ];
        healthCheck.enable = true;
      };

      teenix.services.traefik.services.authentik_auth = {
        router.rule = "Host(`${opts.hostname}`) && PathPrefix(`/outpost.goauthentik.io/`)";
        servers = [ "http://${config.containers.authentik.config.networking.hostName}:9000/outpost.goauthentik.io" ];
      };

      teenix.containers.authentik = {
        config = ./container.nix;
        networking = {
          useResolvConf = true;
          ports.tcp = [ 80 9000 ];
        };

        mounts = {
          logs.paths = [ "authentik" ];
          sops.templates = [ config.sops.templates.authentik ];
          postgres.enable = true;
        };
      };
    };
}
