{ pkgs
, inputs
, lib
, host-config
, ...
}: {
  users.users.matrix-intern-bot = {
    home = "/home/matrix-intern-bot";
    uid = 1000;
    group = "users";
    isNormalUser = true;
  };

  systemd.services.fscs-intern-bot = {
    description = "Serve matrix intern bot";
    after = [ "network.target" ];
    serviceConfig = {
      EnvironmentFile = host-config.sops.secrets.matrix-intern-bot.path;
      Type = "exec";
      User = "matrix-intern-bot";
      WorkingDirectory = "/home/matrix-intern-bot/";
      ExecStart = "${inputs.matrix-intern-bot.packages."${pkgs.stdenv.hostPlatform.system}".default}/bin/matrix-intern-bot";
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

