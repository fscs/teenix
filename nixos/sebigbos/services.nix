{ config, lib, ... }:
let
  ipPoolOf =
    name:
    lib.lists.findFirstIndex (x: x == name) (throw "unreachable") (
      lib.attrNames config.teenix.meta.services
    );
in
{
  sops.secrets.fscshhude-acme-eab-kid = {
    sopsFile = ../secrets/fscshhude.yml;
    key = "acme-eab-kid";
    mode = "0444";
  };
  sops.secrets.fscshhude-acme-eab-hmac-encoded = {
    sopsFile = ../secrets/fscshhude.yml;
    key = "acme-eab-hmac-encoded";
    mode = "0444";
  };

  teenix.services.traefik.staticConfig.certificatesResolvers = {
    uniintern.acme = {
      email = "fscs@hhu.de";
      storage = "${config.teenix.persist.subvolumes.traefik.path}/hhucerts.json";
      tlsChallenge = { };
      caServer = "https://acme.sectigo.com/v2/OV";
      eab = {
        kid = config.sops.placeholder.fscshhude-acme-eab-kid;
        hmacEncoded = config.sops.placeholder.fscshhude-acme-eab-hmac-encoded;
      };
    };
  };

  teenix.services.traefik.httpServices = {
    fscshhude = {
      router.rule = "Host(`fscs.hhu.de`)";
      router.tls.certResolver = lib.mkForce "uniintern";
      healthCheck.enable = true;
      servers = [ "http://192.18.${toString (ipPoolOf "fscshhude")}.11:8080" ];
    };

    hhu-fscs = {
      router.rule = "Host(`hhu-fscs.de`) || Host(`www.hhu-fscs.de`)";
      healthCheck.enable = true;
      servers = [ "http://192.18.${toString (ipPoolOf "fscshhude")}.11:8080" ];
    };
  };

  teenix.config.defaultContainerNetworkId = "10.0";

  teenix.persist.enable = true;

  teenix.services.traefik = {
    enable = true;

    letsencryptMail = "fscs@hhu.de";

    dashboard = {
      enable = true;
      url = "traefik.sebigbos.hhu-fscs.de";
    };
  };

  teenix.services.traefik.middlewares.authentik.forwardAuth = {
    address = "http://192.18.${toString (ipPoolOf "authentik")}.11:9000/outpost.goauthentik.io/auth/traefik";
    tls.insecureSkipVerify = true;
    authResponseHeaders = [
      "X-authentik-username"
      "X-authentik-groups"
      "X-authentik-entitlements"
      "X-authentik-email"
      "X-authentik-name"
      "X-authentik-uid"
      "X-authentik-jwt"
      "X-authentik-meta-jwks"
      "X-authentik-meta-outpost"
      "X-authentik-meta-provider"
      "X-authentik-meta-app"
      "X-authentik-meta-version"
    ];
  };

  # HA
  teenix.meta.ha.enable = true;
  teenix.meta.ha.sopsFile = ../secrets/patroni.yml;

  teenix.ha.ntfy = {
    hostname = config.teenix.meta.services.ntfy.hostname;
    port = 8080;
  };

  teenix.ha.sitzungsverwaltung = {
    hostname = config.teenix.meta.services.sitzungsverwaltung.hostname;
    port = 8080;
  };

  teenix.ha.atticd = {
    hostname = config.teenix.meta.services.atticd.hostname;
    port = 8080;
  };

  teenix.ha.docnix = {
    hostname = config.teenix.meta.services.docnix.hostname;
    port = 8000;
  };

  teenix.ha.fscshhude = {
    hostname = config.teenix.meta.services.fscshhude.hostname;
    port = 8080;
    database = {
      name = "fscshhude";
      username = "fscshhude";
    };
  };

  teenix.ha.static-files = {
    hostname = config.teenix.meta.services.static-files.hostname;
    port = 8080;
  };

  # hacky mchack
  teenix.services.traefik.httpServices.tuer-sensor-private = {
    router = {
      rule = "Host(`${config.teenix.meta.services.tuer-sensor.hostname}`) && PathPrefix(`/update`)";
      middlewares = ["onlyhhudy"];
      # extraConfig.priority = 1000;
    };

    inherit (config.teenix.services.traefik.httpServices.tuer-sensor) servers;
  };

  teenix.ha.tuer-sensor = {
    hostname = config.teenix.meta.services.tuer-sensor.hostname;
    port = 8080;
  };

  teenix.services.prometheus = {
    enable = true;
    hostnames = {
      prometheus = config.teenix.meta.services.prometheus.hostname;
      grafana = "grafana.hhu-fscs.de";
    };
    secretsFile = ../secrets/prometheus.yml;
  };
}
