{ pkgs
, inputs
, host-config
, ...
}: {
  users.users.fscs-hhu = {
    home = "/home/fscs-hhu";
    group = "users";
    isNormalUser = true;
  };

  environment.systemPackages = [
    inputs.fscs-intern-bot.packages."${pkgs.stdenv.hostPlatform.system}".serve
  ];

  systemd.services.fscs-intern-bot = {
    description = "Serve FSCS intern bot";
    after = [ "network.target" ];
    serviceConfig = {
      EnvironmentFile = host-config.sops.secrets.fscs-intern-bot.path;
      Type = "exec";
      User = "fscs-hhu";
      WorkingDirectory = "/home/fscs-hhu";
      ExecStart = "${inputs.fscs-intern-bot.packages."${pkgs.stdenv.hostPlatform.system}".serve}/bin/serve";
      Restart = "always";
      RestartSec = 5;
    };
    wantedBy = [ "multi-user.target" ];
  };

  services.resolved.enable = true;

  system.stateVersion = "23.11";
}
