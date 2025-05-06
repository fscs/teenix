{ config, lib, ... }:
{
  teenix.config.defaultContainerNetworkId = "10.0";

  teenix.persist.enable = true;

  networking.firewall = {
    checkReversePath = false;
    logRefusedConnections = true;
    allowedTCPPorts = [
      2377
    ];
  };

  teenix.services.traefik.staticConfig = {
    providers = {
      swarm = {
        endpoint = "unix:///var/run/docker.sock";
      };
    };
  };

  teenix.services.traefik.entryPoints = {
    metrics = {
      port = 120;
    };
  };

  # enable traefiks metrics, so prometheus can read them
  teenix.services.traefik.staticConfig.metrics.prometheus = {
    entryPoint = "metrics";
    buckets = [
      0.1
      0.3
      1.2
      5.0
    ];
    addEntryPointsLabels = true;
    addServicesLabels = true;
  };

  teenix.services.traefik = {
    enable = true;

    letsencryptMail = "fscs@hhu.de";

    dashboard = {
      enable = true;
      url = "traefik.sebigbos.hhu-fscs.de";
    };
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
