{ ... }:
{
  # irgendwie müssen wir das nicht hardcoden
  
  teenix.services.gatus = {
    enable = true;
    hostname = "status.phynix-hhu.de";

    groups = {
      websites = {
        name = "Websites";
        endpoints = {
          fscs = {
            name = "Fachschaft Informatik Website";
            url = "https://fscs.hhu.de";
          };

          nawi = {
            name = "Fachschaft Nawi Website";
            url = "https://fsnawi.de";
          };

          physik = {
            name = "Fachschaft Physik Website";
            url = "https://fsphy.de";
          };

          phynix = {
            name = "PhyNIx Website";
            url = "https://phynix-hhu.de";
          };

          inphimade = {
            name = "INPhiMa Website";
            url = "https://inphima.de";
          };
        };
      };

      fscs = {
        name = "FS Info Random Zeugs";
        endpoints = {
          sitzungsverwaltung = {
            name = "FSCS Sitzungsverwaltung";
            url = "https://sitzungen.hhu-fscs.de";
          };
          freescout = {
            name = "Freescout";
            url = "https://tickets.hhu-fscs.de";
          };
          attic = {
            name = "Attic";
            url = "https://attic.hhu-fscs.de";
          };
          docnix = {
            name = "Teenix Doku";
            url = "https://docnix.hhu-fscs.de";
          };
          bahn-monitor = {
            name = "Bahn Monitor";
            url = "https://bahn.phynix-hhu.de";
          };
        };
      };

      misc = {
        name = "Miscellaneous";
        endpoints = {
          authentik = {
            name = "Authentik";
            url = "https://auth.phynix-hhu.de";
          };
          campus-guesser = {
            name = "Campus Guesser";
            url = "https://campusguesser.phynix-hhu.de/randomFact";
          };
          vaultwarden = {
            name = "Vaultwarden";
            url = "https://vaultwarden.phynix-hhu.de";
          };
        };
      };

      orga = {
        name = "Orga Tools";
        endpoints = {
          helfendentool = {
            name = "Helfendentool";
            url = "https://helfende.phynix-hhu.de";
          };
          pretix = {
            name = "Pretix";
            url = "https://pretix.phynix-hhu.de";
          };
          crabfit = {
            name = "Crabfit";
            url = "https://crabfit.phynix-hhu.de";
          };
          crabfit-api = {
            name = "Crabfit API";
            url = "https://api.crabfit.phynix-hhu.de";
          };
        };
      };

      nextcloud = {
        name = "Nextcloud + Klausur Archiv";
        endpoints = {
          nextcloud = {
            name = "NextCloud";
            url = "https://nextcloud.phynix-hhu.de";
          };

          collabora = {
            name = "NextCloud Office";
            url = "https://collabora.phynix-hhu.de";
          };

          klausur-archiv = {
            name = "Klausur Archiv";
            url = "https://klausur.phynix-hhu.de";
          };
        };
      };

      monitoring = {
        name = "Monitoring";
        endpoints = {
          prometheus = {
            name = "Prometheus";
            url = "https://prometheus.hhu-fscs.de";
          };
          grafana = {
            name = "Grafana";
            url = "https://grafana.hhu-fscs.de";
          };
          ntfy = {
            name = "Ntfy";
            url = "https://ntfy.hhu-fscs.de";
          };
        };
      };

      hosts = {
        name = "Hosts";
        endpoints = {
          teefax = {
            name = "Teefax";
            url = "ssh://teefax.hhu-fscs.de";
            status = null;
            extraConfig = {
              conditions = [ "[CONNECTED] == true" ];
              ssh = {
                username = "";
                password = "";
              };
            };
          };
          verleihnix = {
            name = "Verleihnix";
            url = "ssh://verleihnix.hhu-fscs.de";
            status = null;
            extraConfig = {
              conditions = [ "[CONNECTED] == true" ];
              ssh = {
                username = "";
                password = "";
              };
            };
          };
          sebigbos = {
            name = "Sebigbos";
            url = "ssh://sebigbos.hhu-fscs.de";
            status = null;
            extraConfig = {
              conditions = [ "[CONNECTED] == true" ];
              ssh = {
                username = "";
                password = "";
              };
            };
          };
        };
      };
    };
  };
}
