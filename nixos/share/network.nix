{ config, ... }:
{
  teenix.persist.subvolumes.system.directories = {
    "/var/lib/fail2ban" = {
      mode = "0750";
    };
    "/var/log/traefik" = {
      mode = "0777";
    };
    "/var/lib/traefik" = {
      mode = "0777";
    };
  };

  services.fail2ban = {
    enable = true;
    ignoreIP = [ "134.99.147.0/24" ];
    bantime-increment.enable = true;
    jails = {
      traefik-400.settings = {
        filter = "traefik-general-forceful-browsing";
        logpath = config.teenix.services.traefik.staticConfig.accessLog.filePath;
        backend = "polling";
        maxretry = 50;
        findtime = 1;
        bantime = 86400;
        action = "iptables[name=Traefik, port=https, protocol=tcp]";
      };
      traefik.settings = {
        filter = "traefik-general";
        logpath = config.teenix.services.traefik.staticConfig.accessLog.filePath;
        backend = "polling";
        maxretry = 200;
        findtime = 1;
        bantime = 600;
        action = "iptables[name=Traefik, port=https, protocol=tcp]";
      };
      traefik-longtime.settings = {
        filter = "traefik-general";
        logpath = config.teenix.services.traefik.staticConfig.accessLog.filePath;
        backend = "polling";
        maxretry = 180000;
        findtime = 1800;
        bantime = 3600;
        action = "iptables[name=Traefik, port=https, protocol=tcp]";
      };
    };
  };

  teenix.services.traefik.staticConfig.accessLog = {
    filePath = "/var/log/traefik/access.log";
    format = "json";
    bufferingSize = 0;
    fields.headers = {
      defaultMode = "drop";
      names.UserAgent = "keep";
    };
  };

  environment.etc."fail2ban/filter.d/traefik-general-forceful-browsing.conf".text = ''
    [Definition]
    # failregex: Match all 4xx errors
    failregex = .*"ClientHost":"<HOST>".*"OriginStatus":4[0-9]{2}.*

    # ignoreregex: Exclude 404 errors
    ignoreregex = .*"ClientHost":"<HOST>".*"OriginStatus":404.*
  '';

  environment.etc."fail2ban/filter.d/traefik-general.conf".text = ''
    [Definition]

    # fail regex based on traefik JSON access logs with enabled user agent logging
    failregex = .*"ClientHost":"<HOST>".*"OriginStatus":(2[0-9]{2}|404).*
  '';
}
