{ pkgs
, inputs
, lib
, host-config
, ...
}: {
  users.users.discord-intern-bot = {
    home = "/home/discord-intern-bot";
    group = "users";
    isNormalUser = true;
  };

  systemd.services.fscs-intern-bot = {
    description = "Serve discord intern bot";
    after = [ "network.target" ];
    serviceConfig = {
      EnvironmentFile = host-config.sops.secrets.discord-intern-bot.path;
      Type = "exec";
      User = "discord-intern-bot";
      WorkingDirectory = "/home/discord-intern-bot/";
      ExecStart = "${inputs.discord-intern-bot.packages."${pkgs.stdenv.hostPlatform.system}".default}/bin/discord-intern-bot";
      Restart = "always";
      RestartSec = 5;
    };
    wantedBy = [ "multi-user.target" ];
  };

  networking = {
    firewall = {
      enable = true;
    };
    # Use systemd-resolved inside the container
    # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
    useHostResolvConf = lib.mkForce false;
  };

  services.resolved.enable = true;

  system.stateVersion = "23.11";
}

