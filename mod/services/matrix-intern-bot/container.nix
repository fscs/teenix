{
  pkgs,
  inputs,
  host-config,
  ...
}:
{

  users.groups.matrix-intern-bot = { };
  users.users.matrix-intern-bot = {
    isSystemUser = true;
    group = "matrix-intern-bot";
  };

  systemd.services.fscs-intern-bot = {
    description = "Serve matrix intern bot";
    after = [ "network.target" ];
    serviceConfig = {
      EnvironmentFile = host-config.sops.templates.matrix-intern-bot.path;
      Type = "exec";
      User = "matrix-intern-bot";
      StateDirectory = "matrix-intern-bot";
      WorkingDirectory = "/var/lib/matrix-intern-bot";
      ExecStart = "${
        inputs.matrix-intern-bot.packages.${pkgs.stdenv.system}.default
      }/bin/matrix-intern-bot";
      Restart = "always";
      RestartSec = 5;
    };
    wantedBy = [ "multi-user.target" ];
  };

  system.stateVersion = "23.11";
}
