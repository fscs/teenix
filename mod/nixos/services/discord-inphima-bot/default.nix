{
  lib,
  config,
  ...
}:
{
  options.teenix.services.discord-inphima-bot = {
    enable = lib.mkEnableOption "setup discord-inphima-bot";
    secretsFile = lib.teenix.mkSecretsFileOption "discord-inphima-bot";
  };

  config =
    let
      cfg = config.teenix.services.discord-inphima-bot;
    in
    lib.mkIf cfg.enable {
      sops = {
        secrets.discord-inphima-bot-token = {
          sopsFile = cfg.secretsFile;
          key = "token";
        };

        templates.discord-inphima-bot.mode = "444";
        templates.discord-inphima-bot.content = ''
          authToken=${config.sops.placeholder.discord-inphima-bot-token}
          botOwner= # unused?
          prefix=! # unused?
          newName=Keine Sonderzeichen
          regex=[\\p{IsLatin}\\p{InGreek}].*+
          negateRegex=[^[\\p{IsLatin}\\p{InGreek}]]
          amongUsId=
        '';
      };

      teenix.containers.discord-inphima-bot = {
        config = ./container.nix;

        networking.useResolvConf = true;

        mounts = {
          data.enable = true;
          data.ownerUid = config.containers.discord-inphima-bot.config.users.users.discord-inphima-bot.uid;

          sops.templates = [ "discord-inphima-bot" ];
        };
      };
    };
}
