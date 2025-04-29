{
  lib,
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
      };

      services.traefik.dynamicConfigOptions = {
        http.routers.fscshhude.tls.certResolver = lib.mkForce "uniintern";
      };

      teenix.services.traefik.services = {
        fscshhude = {
          router.rule = "Host(`fscs.hhu.de`) || Host(`fscs.uni-duesseldorf.de`)";
          healthCheck.enable = true;
          servers = [ "http://${config.containers.fscshhude.localAddress}:8080" ];
        };
        hhu-fscs = {
          router.rule = "Host(`hhu-fscs.de`) || Host(`www.hhu-fscs.de`)";
          healthCheck.enable = true;
          servers = [ "http://${config.containers.fscshhude.localAddress}:8080" ];
        };
      };

      teenix.containers.fscshhude = {
        config = ./container.nix;

        networking = {
          useResolvConf = true;
          ports.tcp = [ 8080 ];
        };

        mounts = {
          postgres.enable = true;
          sops.secrets = [ "fscshhude-env" ];

          data = {
            enable = true;
            name = "fscs-website-server";
          };
        };
      };
    };
}
