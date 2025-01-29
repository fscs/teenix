{
  lib,
  config,
  ...
}:
{
  options.teenix.services.discord-intern-bot = {
    enable = lib.mkEnableOption "setup discord-intern-bot";
    secretsFile = lib.teenix.mkSecretsFileOption "discord-intern-bot";
    dbHostPath = lib.mkOption {
      type = lib.types.str;
    };
  };

  config =
    let
      opts = config.teenix.services.discord-intern-bot;
    in
    lib.mkIf opts.enable {
      sops.secrets.discord-intern-bot-env = {
        sopsFile = opts.secretsFile;
        key = "env";
        mode = "444";
      };

      teenix.containers.discord-intern-bot = {
        config = ./container.nix;

        networking.useResolvConf = true;

        mounts = {
          data = {
            enable = true;
            ownerUid = config.containers.discord-intern-bot.config.users.users.discord-intern-bot.uid;
          };

          sops.secrets = [
            config.sops.secrets.discord-intern-bot-env
          ];
        };
      };
    };
}
