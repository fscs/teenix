{ lib, ... }:
{
  sops.secrets.traefik = {
    format = "binary";
    mode = "444";
    sopsFile = ../secrets/traefik;
  };

  teenix.services.traefik.enable = true;
  teenix.services.traefik.staticConfigPath = ../secrets/traefik_static;
  teenix.services.traefik.dashboardUrl = "traefik.hhu-fscs.de";
  teenix.services.traefik.letsencryptMail = "fscs@hhu.de";
  teenix.services.traefik.logging.enable = true;

  teenix.services.traefik.entrypoints =
    {
      web = {
        port = 80;
        http = {
          redirections = {
            entryPoint = {
              to = "websecure";
              scheme = "https";
            };
          };
        };
      };
      websecure = {
        port = 443;
      };
      ping = {
        port = 8082;
      };
      metrics = {
        port = 120;
      };
    }
    // (builtins.foldl' lib.trivial.mergeAttrs { } (
      builtins.map
        (i: {
          "turn_port_udp_${builtins.toString i}" = {
            port = i;
          };
        })
        (lib.range 30000 30010)
    ));
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
      to = "grafana.hhu-fscs.de/public-dashboards/84a25d574e334559b2095f1d5c573be6";
    };

    voltwarden = {
      from = "voltwarden.inphima.de";
      to = "vaultwarden.inphima.de";
    };

    matewarden = {
      from = "matewarden.inphima.de";
      to = "vaultwarden.inphima.de";
    };
  };
}
