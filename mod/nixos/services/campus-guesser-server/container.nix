{
  pkgs,
  inputs,
  lib,
  config,
  host-config,
  ...
}:
{
  users.groups.campus-guesser-server = { };
  users.users.campus-guesser-server = {
    isSystemUser = true;
    group = "campus-guesser-server";
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [
      config.users.users.campus-guesser-server.name
    ];
    ensureUsers = lib.singleton {
      name = config.users.users.campus-guesser-server.name;
      ensureDBOwnership = true;
    };
    authentication = ''
      local all       all     trust
      host  all       all     all trust
    '';
  };

  systemd.services.campus-guesser-server = {
    description = "Serve the CampusGuesser Server";
    after = [ "network.target" ];
    serviceConfig = {
      Type = "exec";
      Environment = "SPRING_DATASOURCE_USERNAME='campus-guesser-server' SPRING_DATASOURCE_URL='jdbc:postgresql://localhost:5432/campus-guesser-server'";
      EnvironmentFile = host-config.sops.templates.campus-guesser-server.path;
      User = "campus-guesser-server";
      ExecStart = lib.getExe inputs.campus-guesser-server.packages."${pkgs.stdenv.system}".default;
      Restart = "always";
      RestartSec = 5;
    };
    wantedBy = [ "multi-user.target" ];
  };

  system.stateVersion = "23.11";
}
