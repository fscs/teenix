{ lib
, inputs
, pkgs
, host-config
, ...
}: {
  networking.hostName = "fscshhude";
  users.users.fscs-hhu = {
    uid = 1001;
    home = "/home/fscs-hhu";
    group = "users";
    shell = pkgs.bash;
    isNormalUser = true;
  };

  environment.systemPackages = [
    inputs.fscshhude.packages."${pkgs.stdenv.hostPlatform.system}".serve
    pkgs.bash
  ];

  systemd.services.fscs-website-serve = {
    description = "Serve FSCS website";
    after = [ "network.target" ];
    path = [ pkgs.bash ];
    serviceConfig = {
      EnvironmentFile = host-config.sops.secrets.fscshhude.path;
      Type = "exec";
      User = "fscs-hhu";
      WorkingDirectory = "/home/fscs-hhu";
      ExecStart = "${inputs.fscshhude.packages."${pkgs.stdenv.hostPlatform.system}".serve}/bin/serve";
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
