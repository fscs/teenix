{ lib, config, ... }:
{
  teenix.services.traefik = {
    enable = true;
    letsencryptMail = "fscs@hhu.de";
    dashboard = {
      enable = true;
      url = "traefik.phynix-hhu.de";
    };
  };

  teenix.services.traefik.dynamicConfig.http.routers.inphima-to-phynix =
    let
      subdomains = [
        # services
        "auth"
        "bahn"
        "campusguesser"
        "collabora"
        "crabfit"
        "helfendentool"
        "nextcloud"
        "pretix"
        "traefi"
        "vaultwarden"

        # redirects (that always have been redirects)
        "awareness"
        "cloud"
        "discord"
        "doodle"
        "essen"
        "helfen"
        "helfende"
        "helfer"
        "klausur"
        "matewarden"
        "nawi"
        "nextcloud"
        "physik"
        "shop"
        "slinky"
        "status"
        "voltwarden"
        "wanntripper"
        "wiki"
      ];
    in
    {
      rule = lib.concatMapStringsSep " || " (subdomain: "Host(`${subdomain}.inphima.de`)") subdomains;
      service = "blank";
      priority = 10;
      middlewares = "inphima-to-phynix";
      tls.certResolver = "letsencrypt";
      entryPoints = [ "websecure" ];
    };

  teenix.services.traefik.middlewares.inphima-to-phynix = {
    redirectRegex = {
      regex = "inphima.de";
      replacement = "phynix-hhu.de";
      permanent = true;
    };
  };

  teenix.services.traefik.redirects = {
    fscs_go = {
      from = "go.hhu-fscs.de";
      to = "fscs.github.io/go/";
    };

    nawi_phynix = {
      from = "nawi.phynix-hhu.de";
      to = "fsnawi.de";
    };

    informatik_phynix = {
      from = "informatik.phynix-hhu.de";
      to = "fscs.hhu.de";
    };

    discord_phynix = {
      from = "discord.phynix-hhu.de";
      to = "discord.gg/K3ddgjh";
    };

    cloud_phynix = {
      from = "cloud.phynix-hhu.de";
      to = "nextcloud.phynix-hhu.de";
    };

    klausur_phynix = {
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

    essen_phynix = {
      from = "essen.phynix-hhu.de";
      to = "www.stw-d.de/gastronomie/speiseplaene/essenausgabe-sued-duesseldorf";
    };

    wiki_phynix_de = {
      from = "wiki.phynix-hhu.de";
      to = "wiki.hhu.de/display/INPHIMA";
    };

    wiki_fsnawi = {
      from = "wiki.fsnawi.de";
      to = "wiki.hhu.de/display/NAWI";
    };

    physik_phynix = {
      from = "physik.phynix-hhu.de";
      to = "fsphy.de";
    };

    status_phynix = {
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

    phynix_awareness = {
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
