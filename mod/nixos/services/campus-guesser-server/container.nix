{ pkgs
, inputs
, lib
, config
, host-config
, ...
}: {
  users.users.campus-guesser-server = {
    home = "/home/campus-guesser-server";
    group = "users";
    isNormalUser = true;
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [
      config.users.users.campus-guesser-server.name
    ];
    ensureUsers = [
      {
        name = config.users.users.campus-guesser-server.name;
        ensureDBOwnership = true;
      }
    ];
    authentication = pkgs.lib.mkOverride 10 ''
      local all       all     trust
      host  all       all     all trust
    '';
  };

  environment.systemPackages = [
    inputs.campus-guesser-server.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  systemd.services.campus-guesser-server = {
    description = "Serve the CampusGuesser Server";
    after = [ "network.target" ];
    serviceConfig = {
      Type = "exec";
      Environment = "SPRING_DATASOURCE_USERNAME='campus-guesser-server' SPRING_DATASOURCE_URL='jdbc:postgresql://localhost:5432/campus-guesser-server'";
      EnvironmentFile = host-config.sops.secrets.campusguesser.path;
      User = "campus-guesser-server";
      ExecStart = "${inputs.campus-guesser-server.packages."${pkgs.stdenv.hostPlatform.system}".default}/bin/CampusGuesserServer-fscs";
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
