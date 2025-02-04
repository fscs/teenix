{
  pkgs,
  inputs,
  lib,
  host-config,
  ...
}:
{
  users.users.discord-intern-bot = {
    uid = 1000;
    isNormalUser = true;
  };

  systemd.services.fscs-intern-bot = {
    description = "Serve discord intern bot";
    after = [ "network.target" ];
    serviceConfig = {
      EnvironmentFile = host-config.sops.secrets.discord-intern-bot-env.path;
      Type = "exec";
      User = "discord-intern-bot";
      WorkingDirectory = "/var/lib/discord-intern-bot/";
      StateDirectory = "/var/lib/discord-intern-bot";
      ExecStart = lib.getExe inputs.discord-intern-bot.packages."${pkgs.stdenv.system}".default;
      Restart = "always";
      RestartSec = 5;
    };
    wantedBy = [ "multi-user.target" ];
  };

  system.stateVersion = "23.11";
}
