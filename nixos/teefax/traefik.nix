{ lib, config, ... }:
{
  sops.secrets.traefik = {
    format = "binary";
    mode = "444";
    sopsFile = ../secrets/traefik;
  };

  teenix.services.traefik = {
    enable = true;
    staticConfigPath = ../secrets/traefik_static;
    dashboardUrl = "traefik.phynix-hhu.de";
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

    nawi_phynix = {
      from = "nawi.phynix-hhu.de";
      to = "fsnawi.de";
    };

    discord_inphimade = {
      from = "discord.phynix-hhu.de";
      to = "discord.gg/K3ddgjh";
    };

    cloud_inphima = {
      from = "cloud.phynix-hhu.de";
      to = "nextcloud.phynix-hhu.de";
    };

    klausur_inphima = {
      from = "klausur.phynix-hhu.de";
      to = "nextcloud.phynix-hhu.de/s/K6xSKSXmJRQAiia";
    };

    helfer_redirect = {
      from = "helfer.phynix-hhu.de";
      to = "helfendentool.phynix-hhu.de";
    };

    helfen_redirect = {
      from = "helfen.phynix-hhu.de";
      to = "helfendentool.phynix-hhu.de";
    };

    helfende_redirect = {
      from = "helfende.phynix-hhu.de";
      to = "helfendentool.phynix-hhu.de";
    };

    essen_inphima = {
      from = "essen.phynix-hhu.de";
      to = "www.stw-d.de/gastronomie/speiseplaene/essenausgabe-sued-duesseldorf";
    };

    wiki_inphima_de = {
      from = "wiki.phynix-hhu.de";
      to = "wiki.hhu.de/display/INPHIMA/INPhiMa+Startseite";
    };

    wiki_fsnawi = {
      from = "wiki.fsnawi.de";
      to = "wiki.hhu.de/display/NAWI/FS+Naturwissenschaften+Startseite";
    };

    physik_inphima = {
      from = "physik.phynix-hhu.de";
      to = "fsphy.de";
    };

    status_inphima = {
      from = "status.phynix-hhu.de";
      to = "uptime.dev.hhu-fscs.de/status/inphima";
    };

    voltwarden = {
      from = "voltwarden.phynix-hhu.de";
      to = config.teenix.services.vaultwarden.hostname;
    };

    matewarden = {
      from = "matewarden.phynix-hhu.de";
      to = config.teenix.services.vaultwarden.hostname;
    };

    inphima_shop = {
      from = "shop.phynix-hhu.de";
      to = "inphima.myspreadshop.de/";
    };

    inphima_awareness = {
      from = "awareness.phynix-hhu.de";
      to = "nextcloud.phynix-hhu.de/s/jTay3AMBRt8dQwD";
    };

    slinky = {
      from = "slinky.phynix-hhu.de";
      to = "www.legami.com/de_de/magic-spring-VSL0001.html";
    };

    wanntripper = {
      from = "wanntripper.phynix-hhu.de";
      to = config.teenix.services.crabfit.hostnames.frontend;
    };

    doodle = {
      from = "doodle.phynix-hhu.de";
      to = config.teenix.services.crabfit.hostnames.frontend;
    };
  };
}
