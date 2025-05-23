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
      traefik.settings = {
        filter = "traefik-general-forceful-browsing";
        logpath = config.teenix.services.traefik.staticConfig.accessLog.filePath;
        maxretry = 5;
        findtime = 3600;
        bantime = 86400;
        action = "iptables[name=Traefik, port=http, protocol=tcp]";
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
    [INCLUDES]

    [Definition]

    # fail regex based on traefik JSON access logs with enabled user agent logging
    failregex = ^{"ClientAddr":"<F-CLIENTADDR>.*</F-CLIENTADDR>","ClientHost":"<HOST>","ClientPort":"<F-CLIENTPORT>.*</F-CLIENTPORT>","ClientUsername":"<F-CLIENTUSERNAME>.*</F-CLIENTUSERNAME>","DownstreamContentSize":<F-DOWNSTREAMCONTENTSIZE>.*</F-DOWNSTREAMCONTENTSIZE>,"DownstreamStatus":<F-DOWNSTREAMSTATUS>.*</F-DOWNSTREAMSTATUS>,"Duration":<F-DURATION>.*</F-DURATION>,"OriginContentSize":<F-ORIGINCONTENTSIZE>.*</F-ORIGINCONTENTSIZE>,"OriginDuration":<F-ORIGINDURATION>.*</F-ORIGINDURATION>,"OriginStatus":(405|404|403|402|401),"Overhead":<F-OVERHEAD>.*</F-OVERHEAD>,"RequestAddr":"<F-REQUESTADDR>.*</F-REQUESTADDR>","RequestContentSize":<F-REQUESTCONTENTSIZE>.*</F-REQUESTCONTENTSIZE>,"RequestCount":<F-REQUESTCOUNT>.*</F-REQUESTCOUNT>,"RequestHost":"<F-CONTAINER>.*</F-CONTAINER>","RequestMethod":"<F-REQUESTMETHOD>.*</F-REQUESTMETHOD>","RequestPath":"<F-REQUESTPATH>.*</F-REQUESTPATH>","RequestPort":"<F-REQUESTPORT>.*</F-REQUESTPORT>","RequestProtocol":"<F-REQUESTPROTOCOL>.*</F-REQUESTPROTOCOL>","RequestScheme":"<F-REQUESTSCHEME>.*</F-REQUESTSCHEME>","RetryAttempts":<F-RETRYATTEMPTS>.*</F-RETRYATTEMPTS>,.*"StartLocal":"<F-STARTLOCAL>.*</F-STARTLOCAL>","StartUTC":"<F-STARTUTC>.*</F-STARTUTC>","TLSCipher":"<F-TLSCIPHER>.*</F-TLSCIPHER>","TLSVersion":"<F-TLSVERSION>.*</F-TLSVERSION>","entryPointName":"<F-ENTRYPOINTNAME>.*</F-ENTRYPOINTNAME>","level":"<F-LEVEL>.*</F-LEVEL>","msg":"<F-MSG>.*</F-MSG>",("request_User-Agent":"<F-USERAGENT>.*</F-USERAGENT>",){0,1}?"time":"<F-TIME>.*</F-TIME>"}$

    datepattern = "StartLocal"\s*:\s*"%%Y-%%m-%%d[T]%%H:%%M:%%S\.%%f\d*(%%z)?",
  '';

}
