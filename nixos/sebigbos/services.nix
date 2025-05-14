{ config, lib, ... }:
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

  teenix.services.traefik.httpServices =
    let
      ipPoolOf =
        name:
        lib.lists.findFirstIndex (x: x == name) (throw "unreachable") (
          lib.attrNames config.teenix.meta.services
        );
    in
    {
      fscshhude = {
        router.rule = "Host(`fscs.hhu.de`)";
        router.tls.certResolver = "uniintern";
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

  teenix.services.traefik.middlewares.authentik.forwardAuth =
    let
      ipPoolOf =
        name:
        lib.lists.findFirstIndex (x: x == name) (throw "unreachable") (
          lib.attrNames config.teenix.meta.services
        );
    in
    {
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

  teenix.meta.ha.enable = true;

  teenix.ha.ntfy = {
    hostname = config.teenix.meta.services.ntfy.hostname;
    port = 8080;
  };

  teenix.ha.sitzungsverwaltung = {
    hostname = config.teenix.meta.services.sitzungsverwaltung.hostname;
    port = 8080;
  };

  teenix.ha.prometheus = {
    hostname = config.teenix.meta.services.prometheus.hostname;
    port = 9090;
  };

  teenix.services.traefik.dynamicConfig =
    let
      ipPoolOf =
        name:
        lib.lists.findFirstIndex (x: x == name) (throw "unreachable") (
          lib.attrNames config.teenix.meta.services
        );
    in
    {
      http = {
        routers = {
          grafana = {
            rule = "Host(`grafana.hhu-fscs.de`)";
            service = "grafana";
            entryPoints = [ "websecure" ];
            tls.certResolver = "letsencrypt";
          };
          hhufscsde = {
            rule = "Host(`hhu-fscs.de`)";
            service = "hhufscsde";
            entryPoints = [ "websecure" ];
            tls.certResolver = "letsencrypt";
          };
          freescout = {
            rule = "Host(`tickets.hhu-fscs.de`)";
            service = "freescout";
            entryPoints = [ "websecure" ];
            tls.certResolver = "letsencrypt";
          };
        };
        services = {
          grafana = {
            loadBalancer = {
              servers = [
                {
                  url = "http://192.18.${toString (ipPoolOf "prometheus")}.11:80";
                }
              ];
            };
          };
          hhufscsde = {
            loadBalancer = {
              servers = [
                {
                  url = "http://192.18.${toString (ipPoolOf "fscshhude")}.11:80";
                }
              ];
            };
          };
          freescout = {
            loadBalancer = {
              servers = [
                {
                  url = "http://192.88.99.2:80";
                }
              ];
            };
          };
        };
      };
    };

  teenix.ha.atticd = {
    hostname = config.teenix.meta.services.atticd.hostname;
    port = 8080;
  };

  teenix.ha.docnix = {
    hostname = config.teenix.meta.services.docnix.hostname;
    port = 8000;
  };

  teenix.ha.static-files = {
    hostname = config.teenix.meta.services.static-files.hostname;
    port = 8080;
  };
}
