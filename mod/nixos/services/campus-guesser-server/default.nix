{
  lib,
  config,
  ...
}:
{
  options.teenix.services.campus-guesser-server = {
    enable = lib.mkEnableOption "setup campus-guesser-server";
    hostname = lib.teenix.mkHostnameOption;
    secretsFile = lib.teenix.mkSecretsFileOption "campus-guesser-server";
  };

  config =
    let
      opts = config.teenix.services.campus-guesser-server;
    in
    lib.mkIf opts.enable {
      sops.secrets.campus-guesser-server-oauth-secret = {
        sopsFile = opts.secretsFile;
        mode = "444";
        key = "oauth-secret";
      };

      sops.templates.campus-guesser-server.content = ''
        OAUTH_SECRET=${config.sops.placeholder.campus-guesser-server-oauth-secret}
      '';

      teenix.services.traefik.services.campus-guessser-server = {
        router.rule = "Host(`${opts.hostname}`)";
        servers = [ "http://${config.containers.campus-guesser-server.localAddress}:8080" ];
        healthCheck.enable = true;
      };

      teenix.containers.campus-guesser-server = {
        config = ./container.nix;

        networking = {
          useResolvConf = true;
          ports.tcp = [ 8080 ];
        };

        mounts = {
          postgres.enable = true; 
          data =  {
            enable = true;          
            ownerUid = config.containers.campus-guesser-server.config.users.users.campus-guesser-server.uid;
          };

          sops.templates = [
            config.sops.templates.campus-guesser-server 
          ];
        };
      };
    };
}
