{ pkgs
, inputs
, lib
, host-config
, ...
}: {
  users.users.fscs-hhu = {
    home = "/home/fscs-hhu";
    group = "users";
    isNormalUser = true;
  };

  systemd.services.fscs-intern-bot = {
    description = "Serve FSCS intern bot";
    after = [ "network.target" ];
    serviceConfig = {
      EnvironmentFile = host-config.sops.secrets.fscs-intern-bot.path;
      Type = "exec";
      User = "fscs-webiste";
      WorkingDirectory = " /home/fscs-website ";
      ExecStart = "${inputs.fscs-intern-bot.packages."${pkgs.stdenv.hostPlatform.system}".fscs-intern-bot}/bin/top-manager-discord";
      Restart = "always";
      RestartSec = 5;
    };
    wantedBy = [ "multi-user.target" ];
  };

  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 8080 ];
    };
    # Use systemd-resolved inside the container
    # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
    useHostResolvConf = lib.mkForce false;
  };

  services.resolved.enable = true;

  system.stateVersion = "23.11";
}

