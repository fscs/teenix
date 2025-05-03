{
  lib,
  config,
  ...
}:
{
  imports = [ ./meta.nix ];

  options.teenix.services.matrix-intern-bot = {
    enable = lib.mkEnableOption "setup matrix-intern-bot";
    secretsFile = lib.teenix.mkSecretsFileOption "matrix-intern-bot";
  };

  config =
    let
      cfg = config.teenix.services.matrix-intern-bot;
    in
    lib.mkIf cfg.enable {
      sops.secrets = {
        matrix-intern-bot-client-secret = {
          sopsFile = cfg.secretsFile;
          key = "client-secret";
        };
        matrix-intern-bot-client-id = {
          sopsFile = cfg.secretsFile;
          key = "client-id";
        };
        matrix-intern-bot-password = {
          sopsFile = cfg.secretsFile;
          key = "password";
        };
      };

      sops.templates.matrix-intern-bot.content = ''
        USERNAME=fscs
        CLIENT_ID=${config.sops.placeholder.matrix-intern-bot-client-id}
        CLIENT_SECRET=${config.sops.placeholder.matrix-intern-bot-client-secret}
        PASSWORD=${config.sops.placeholder.matrix-intern-bot-password}
      '';

      teenix.containers.matrix-intern-bot = {
        config = ./container.nix;

        networking.useResolvConf = true;

        mounts = {
          sops.templates = [ "matrix-intern-bot" ];
          data.enable = true;
        };
      };
    };
}
