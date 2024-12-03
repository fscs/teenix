{
  lib,
  pkgs,
  host-config,
  ...
}:
{
  networking.hostName = "node_exporter";
  users.users.node_exporter = {
    uid = 1033;
    home = "/home/node_exporter";
    group = "users";
    shell = pkgs.bash;
    isNormalUser = true;
  };

  systemd.services.node_exporter-serve = {
    description = "Start node exporter";
    after = [ "network.target" ];
    path = [ pkgs.bash ];
    serviceConfig = {
      Type = "exec";
      User = "node_exporter";
      WorkingDirectory = "/home/node_exporter";
      ExecStart = "${pkgs.prometheus-node-exporter}/bin/node_exporter";
      Restart = "always";
      RestartSec = 5;
    };
    wantedBy = [ "multi-user.target" ];
  };

  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 9100 ];
    };
    # Use systemd-resolved inside the container
    # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
    useHostResolvConf = lib.mkForce false;
  };

  services.resolved.enable = true;

  system.stateVersion = "23.11";
}
