{
  lib,
  config,
  ...
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

      teenix.services.traefik = {
        services.authentik = {
          router.rule = "Host(`${opts.hostname}`)";
          servers = [ "http://${config.containers.authentik.localAddress}" ];
          healthCheck.enable = true;
        };

        services.authentik_auth = {
          router.rule = "Host(`${opts.hostname}`) && PathPrefix(`/outpost.goauthentik.io/`)";
          servers = [ "http://${config.containers.authentik.localAddress}:9000/outpost.goauthentik.io" ];
        };

        middlewares.authentik.forwardAuth = {
          address = "https://${config.containers.authentik.localAddress}:9443/outpost.goauthentik.io/auth/traefik";
          trustForwardHeader = true;
          tls.insecureSkipVerify = true;
          authResponseHeaders = [
            "X-authentik-username"
            "X-authentik-groups"
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
          sops.templates = [ config.sops.templates.authentik ];
          postgres.enable = true;
        };
      };
    };
}
