{
  pkgs,
  inputs,
  lib,
  host-config,
  ...
}:
{
  users.groups.discord-inphima-bot = { };
  users.users.discord-inphima-bot = {
    isSystemUser = true;
    uid = 999;
    group = "discord-inphima-bot";
  };

  systemd.services.discord-inphima-bot =
    let
      rssConfig = builtins.toFile "discord-inphima-bot-rss" ''
        last=
        feeds=example-feed
        example-feed-url=https://exampleUrl.exampleTLD/category/categoryName/feed
        example-feed-guild=0
        example-feed-channel=0
      '';
    in
    {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "exec";
        User = "discord-inphima-bot";
        StateDirectory = "/var/lib/discord-inphima-bot";
        EnvironmentFile = builtins.toFile "discord-inphima-bot-env" ''
          INPHIMA_BOT_DATABASE=/var/lib/discord-inphima-bot/db.sqlite
          INPHIMA_BOT_CONFIG=${host-config.sops.templates.discord-inphima-bot.path}
          INPHIMA_BOT_RSS_CONFIG=${rssConfig}
        '';
        ExecStart = lib.getExe inputs.discord-inphima-bot.packages.${pkgs.stdenv.system}.default;
        Restart = "always";
        RestartSec = 5;
      };
    };

  system.stateVersion = "24.11";
}
