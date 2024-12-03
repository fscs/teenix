{
  lib,
  inputs,
  pkgs,
  host-config,
  ...
}:
{

  services.matrix-sliding-sync = {
    enable = true;
    createDatabase = true;
    environmentFile = host-config.sops.secrets.sliding-sync.path;
    settings = {
      SYNCV3_SERVER = "https://matrix.inphima.de";
      SYNCV3_DB = "postgresql:///matrix-sliding-sync?host=/run/postgresql";
      SYNCV3_BINDADDR = "[::]:8009";
    };
  };

  networking.hostName = "sliding-sync";

  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 8009 ];
    };
    # Use systemd-resolved inside the container
    # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
    useHostResolvConf = lib.mkForce false;
  };

  services.resolved.enable = true;

  system.stateVersion = "23.11";
}
