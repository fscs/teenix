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

      sitzungsverwaltung = inputs.sitzungsverwaltung.packages."${pkgs.stdenv.system}".default.override {
        config = {
          OAUTH_CLIENT_ID = "TlIyjVYe4JFAbDkSkyNlVFjkhMLGAtcDW0CU2SIs";
          OAUTH_AUTH_URL = "https://${config.teenix.services.authentik.hostname}/application/o/authorize/";
          OAUTH_TOKEN_URL = "https://${config.teenix.services.authentik.hostname}/application/o/token/";
          OAUTH_USERINFO_URL = "https://${config.teenix.services.authentik.hostname}/application/o/userinfo/";
          OAUTH_ISSUER_URL = "https://${config.teenix.services.authentik.hostname}/application/o/sitzungsverwaltung/";
          OAUTH_JWKS_URL = "https://${config.teenix.services.authentik.hostname}/application/o/sitzungsverwaltung/jwks/";
          API_BASE_URL = "https://fscs.hhu.de/";
        };
      };
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
              ExecStart = "${lib.getExe pkgs.caddy} file-server -r ${sitzungsverwaltung} --listen :8080";
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
