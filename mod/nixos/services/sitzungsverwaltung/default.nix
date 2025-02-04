{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
{
  options.teenix.services.sitzungsverwaltung = {
    enable = lib.mkEnableOption "setup sitzungsverwaltung";
    hostname = lib.teenix.mkHostnameOption;
  };

  config =
    let
      cfg = config.teenix.services.sitzungsverwaltung;
    in
    lib.mkIf cfg.enable {
      teenix.services.traefik.services.sitzungsverwaltung = {
        router.rule = "Host(`${cfg.hostname}`)";
        servers = [ "http://${config.containers.sitzungsverwaltung.localAddress}:8080" ];
      };

      teenix.containers.sitzungsverwaltung = {
        config = {
          systemd.services.sitzungsverwaltung = {
            description = "Serve FSCS sitzungsverwaltung";
            after = [ "network.target" ];
            path = [ pkgs.bash ];
            serviceConfig = {
              Type = "exec";
              DynamicUser = true;
              ExecStart = "${lib.getExe pkgs.caddy} file-server -r ${
                inputs.sitzungsverwaltung.packages."${pkgs.stdenv.system}".default
              } --listen :8080";
              Restart = "always";
              RestartSec = 5;
            };
            wantedBy = [ "multi-user.target" ];
          };

          system.stateVersion = "24.11";
        };

        networking = {
          useResolvConf = true;
          ports.tcp = [ 8080 ];
        };
      };
    };
}
