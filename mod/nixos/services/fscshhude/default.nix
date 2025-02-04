{
  lib,
  inputs,
  pkgs,
  config,
  ...
}:
{
  options.teenix.services.fscshhude = {
    enable = lib.mkEnableOption "setup fscshhude";
    secretsFile = lib.teenix.mkSecretsFileOption "fscshhude";
  };

  config =
    let
      opts = config.teenix.services.fscshhude;
    in
    lib.mkIf opts.enable {
      sops.secrets.fscshhude-env = {
        sopsFile = opts.secretsFile;
        key = "env";
        mode = "444";
      };

      services.traefik.dynamicConfigOptions = {
        http.routers.fscshhude.tls.certResolver = lib.mkForce "uniintern";
      };

      teenix.services.traefik.services."fscshhude" = {
        router.rule = "Host(`fscs.hhu.de`) || Host(`fscs.uni-duesseldorf.de`) || Host(`hhu-fscs.de`)";
        healthCheck = {
          enable = true;
          path = "/de/";
        };
        servers = [ "http://${config.containers.fscshhude.localAddress}:8080" ];
      };

      teenix.containers.fscshhude = {
        config = {
          imports = [ inputs.fscs-website-server.nixosModules.fscs-website-server ];

          users.users.fscs-website-server.uid = 1000;

          services.fscs-website-server = {
            enable = true;
            content = inputs.fscshhude.packages.${pkgs.stdenv.system}.default;
            environmentFile = config.sops.secrets.fscshhude-env.path;
            authUrl = "https://${config.teenix.services.authentik.hostname}/application/o/authorize/";
            tokenUrl = "https://${config.teenix.services.authentik.hostname}/application/o/token/";
            userInfoUrl = "https://${config.teenix.services.authentik.hostname}/application/o/userinfo/";
          };

          system.stateVersion = "24.11";
        };

        networking = {
          useResolvConf = true;
          ports.tcp = [ 8080 ];
        };

        mounts = {
          postgres.enable = true;
          sops.secrets = [ config.sops.secrets.fscshhude-env ];
        };
      };
    };
}
