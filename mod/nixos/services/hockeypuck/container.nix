{
  pkgs,
  lib,
  config,
  host-config,
  ...
}:
{
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "hockeypuck" ];
    ensureUsers = lib.singleton {
      name = "hockeypuck";
      ensureDBOwnership = true;
    };
  };

  services.hockeypuck = {
    enable = true;
    # inline the default config because we DONT want to set logfile (because logs should go to the journal)
    settings.hockeypuck = lib.mkForce {
      hostname = host-config.teenix.services.hockeypuck.hostname;

      loglevel = "INFO";

      indexTemplate = "${pkgs.hockeypuck-web}/share/templates/index.html.tmpl";
      vindexTemplate = "${pkgs.hockeypuck-web}/share/templates/index.html.tmpl";
      statsTemplate = "${pkgs.hockeypuck-web}/share/templates/stats.html.tmpl";
      webroot = "${pkgs.hockeypuck-web}/share/webroot";

      hkp.bind = ":${toString config.services.hockeypuck.port}";

      openpgp.db = {
        driver = "postgres-jsonb";
        dsn = "database=hockeypuck host=/var/run/postgresql sslmode=disable";
      };

      recon.allowCIDRs = [
        host-config.containers.hockeypuck.localAddress
      ];
    };
  };

  system.stateVersion = "24.11";
}
