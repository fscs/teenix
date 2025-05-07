{ config, lib, ... }:
{
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

  teenix.ha.fscshhude = {
    hostname = "fscs.sebigbos.hhu-fscs.de";
    port = 8080;
  };

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
}
