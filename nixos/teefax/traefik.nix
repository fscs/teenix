{ lib, ... }:
{
  sops.secrets.traefik = {
    format = "binary";
    mode = "444";
    sopsFile = ../secrets/traefik;
  };

  teenix.services.traefik = {
    enable = true;
    staticConfigPath = ../secrets/traefik_static;
    dashboardUrl = "traefik.inphima.de";
    letsencryptMail = "fscs@hhu.de";
    logging.enable = true;
    withDocker = true;
  };

  services.traefik.staticConfigOptions.entryPoints = {
    websecure.proxyProtocol.insecure = true;
  };

  teenix.services.traefik.entrypoints = lib.mkMerge [
    {
      web = {
        port = 80;
        http.redirections.entryPoint = {
          to = "websecure";
          scheme = "https";
        };
      };
      websecure = {
        port = 443;
      };
      ping.port = 8082;
      metrics.port = 120;
    }
    (lib.listToAttrs (
      map (i: {
        name = "turn_port_udp_${toString i}";
        value.port = i;
      }) (lib.range 30000 30010)
    ))
  ];

  teenix.services.traefik.redirects = {
    fscs_go = {
      from = "go.hhu-fscs.de";
      to = "fscs.github.io/go/";
    };

    essen_inphima = {
      from = "essen.inphima.de";
      to = "www.stw-d.de/gastronomie/speiseplaene/essenausgabe-sued-duesseldorf";
    };

    wiki_inphima_de = {
      from = "wiki.inphima.de";
      to = "wiki.hhu.de/display/INPHIMA/INPhiMa+Startseite";
    };

    wiki_fsnawi = {
      from = "wiki.fsnawi.de";
      to = "wiki.hhu.de/display/NAWI/FS+Naturwissenschaften+Startseite";
    };

    physik_inphima = {
      from = "physik.inphima.de";
      to = "fsphy.de";
    };

    status_inphima = {
      from = "status.inphima.de";
      to = "uptime.dev.hhu-fscs.de/status/inphima";
    };

    voltwarden = {
      from = "voltwarden.inphima.de";
      to = "vaultwarden.inphima.de";
    };

    matewarden = {
      from = "matewarden.inphima.de";
      to = "vaultwarden.inphima.de";
    };

    inphima_shop = {
      from = "shop.inphima.de";
      to = "inphima.myspreadshop.de/";
    };

    inphima_awareness = {
      from = "awareness.inphima.de";
      to = "nextcloud.inphima.de/s/jTay3AMBRt8dQwD";
    };

    slinky = {
      from = "slinky.inphima.de";
      to = "www.legami.com/de_de/magic-spring-VSL0001.html";
    };
  };
}
