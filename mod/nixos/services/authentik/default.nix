{
  lib,
  config,
  ...
}:
{
  imports = [ ./meta.nix ];
  options.teenix.services.authentik = {
    enable = lib.mkEnableOption "authentik";
    hostname = lib.teenix.mkHostnameOption "authentik";
    secretsFile = lib.teenix.mkSecretsFileOption "authentik";
  };

  config =
    let
      cfg = config.teenix.services.authentik;
    in
    lib.mkIf cfg.enable {
      sops = {
        secrets.authentik-admin-token = {
          sopsFile = cfg.secretsFile;
          key = "admin-token";
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

      teenix.services.traefik.middlewares.authentik.forwardAuth = {
        address = "http://${config.containers.authentik.localAddress}:9000/outpost.goauthentik.io/auth/traefik";
        tls.insecureSkipVerify = true;
        authResponseHeaders = [
          "X-authentik-username"
          "X-authentik-groups"
          "X-authentik-entitlements"
          "X-authentik-email"
          "X-authentik-name"
          "X-authentik-uid"
          "X-authentik-jwt"
          "X-authentik-meta-jwks"
          "X-authentik-meta-outpost"
          "X-authentik-meta-provider"
          "X-authentik-meta-app"
          "X-authentik-meta-version"
        ];
      };

      teenix.services.traefik.httpServices = {
        authentik = {
          router.rule = "Host(`${cfg.hostname}`)";
          servers = [ "http://${config.containers.authentik.localAddress}" ];
          healthCheck.enable = true;
        };
      };

      teenix.containers.authentik = {
        config = ./container.nix;
        networking = {
          useResolvConf = true;
          ports.tcp = [
            80
            9000
            9443
          ];
        };

        mounts = {
          sops.templates = [ "authentik" ];
          postgres.enable = true;
        };
      };
    };
}
