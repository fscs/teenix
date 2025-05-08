{
  lib,
  config,
  ...
}:
{
  imports = [ ./meta.nix ];

  options.teenix.services.engelsystem = {
    enable = lib.mkEnableOption "engelsystem";
    hostname = lib.teenix.mkHostnameOption "engelsystem";
    secretsFile = lib.teenix.mkSecretsFileOption "engelsystem";
  };

  config =
    let
      cfg = config.teenix.services.engelsystem;
    in
    lib.mkIf cfg.enable {
      teenix.services.traefik.httpServices = {
        engelsystem = {
          router.rule = "Host(`${cfg.hostname}`)";
          healthCheck = {
            enable = true;
            path = "/login";
          };
          servers = [
            "http://${config.containers.engelsystem.localAddress}:80"
          ];
        };
      };

      sops.secrets.engelsystem-oauth-client-secret = {
        sopsFile = cfg.secretsFile;
        key = "oauth-client-secret";
      };

      teenix.containers.engelsystem = {
        config = {
          services.engelsystem = {
            enable = true;
            domain = "localhost";
            settings = {
              database = {
                database = "engelsystem";
                host = "localhost";
                username = "engelsystem";
              };
              oauth.authentik = {
                name = "PhyNIx";
                client_id = "IpCvvakLFU3BzGCmSd30zshU9YyCvOal690QyFtA";
                client_secret._secret = config.sops.secrets.engelsystem-oauth-client-secret.path;
                url_auth = "https://auth.phynix-hhu.de/application/o/authorize/";
                url_token = "https://auth.phynix-hhu.de/application/o/token/";
                url_info = "https://auth.phynix-hhu.de/application/o/userinfo/";
                scope = [
                  "openid"
                  "profile"
                  "email"
                  "offline_access"
                ];
                id = "sub";
                username = "preferred_username";
                enable_full_name = true;
                email = "email";
                groups = "groups";
                teams = {
                  "FS_Rat_PhyNIx" = 2;
                };
              };
              default_locale = "de_DE.UTF-8";
              timezone = "Europe/Berlin";
              url = "https://${cfg.hostname}";
            };
          };

          system.stateVersion = "24.11";
        };

        networking = {
          useResolvConf = true;
          ports.tcp = [
            80
          ];
        };

        mounts.mysql.enable = true;
        mounts.sops.secrets = [ "engelsystem-oauth-client-secret" ];
      };
    };
}
