{
  lib,
  pkgs,
  host-config,
  ...
}:
{
  imports = [
    ./mas.nix
    ./hookshot.nix
    ./synapse.nix
    ./element-web.nix
  ];

  environment.systemPackages = [ pkgs.python312Packages.authlib ];

  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];

  teenix.services = {
    mas.enable = true;
    synapse.enable = true;
    matrix-hookshot.enable = true;
  };

  systemd.services.mautrix-discord = {
    description = "Start mautrix discord bridge";
    after = [ "network.target" ];
    path = [ pkgs.bash ];
    serviceConfig = {
      Type = "exec";
      User = "matrix-synapse";
      WorkingDirectory = "/var/lib/matrix-synapse";
      StateDirectory = "matrix-synapse";
      ExecStart = lib.getExe pkgs.mautrix-discord;
      Restart = "always";
      RestartSec = 5;
    };
    wantedBy = [ "multi-user.target" ];
  };

  # enable coturn
  services.coturn = {
    enable = true;
    no-cli = true;
    no-tcp-relay = true;
    min-port = 30000;
    max-port = 30010;
    use-auth-secret = true;
    static-auth-secret-file = host-config.sops.secrets.matrix-turn-secret.path;
    realm = host-config.teenix.services.matrix.hostnames.matrix;
    extraConfig = ''
      turn_allow_guests: true
    '';
  };

  system.stateVersion = "23.11";
}
