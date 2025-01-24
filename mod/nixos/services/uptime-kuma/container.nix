{ pkgs, ... }: {
  system.stateVersion = "23.11";

  systemd.services.uptime-kuma = {
    description = "Uptime Kuma";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      DATA_DIR = "/var/lib/uptime-kuma/";
      NODE_ENV = "production";
      HOST = "0.0.0.0";
      PORT = "3001";
    };
    path = with pkgs; [ unixtools.ping ];
    serviceConfig = {
      Type = "exec";
      ExecStart = "${pkgs.uptime-kuma}/bin/uptime-kuma-server";
      Restart = "always";
      User = "root";
      WorkingDirectory = "/var/lib/uptime-kuma";
      RestartSec = 5;
    };
  };
}
