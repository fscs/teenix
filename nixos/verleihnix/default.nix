{
  inputs,
  outputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../share
    ./hardware-configuration.nix

    outputs.nixosModules.teenix
  ];

  environment.enableAllTerminfo = true;
  environment.systemPackages = [
    pkgs.git
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];

  networking = {
    hostName = "verleihnix";

    nameservers = [ "134.99.128.2" ];

    defaultGateway = {
      address = "134.99.147.33";
      interface = "ens192";
    };

    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "ens192";
      # Lazy IPv6 connectivity for the container
      enableIPv6 = true;
    };

    interfaces.ens160 = {
      ipv4 = {
        addresses = [
          {
            address = "134.99.147.245";
            prefixLength = 27;
          }
        ];
      };
    };

    interfaces.ens192 = {
      ipv4 = {
        addresses = [
          {
            address = "134.99.147.43";
            prefixLength = 27;
          }
        ];
        routes = lib.singleton {
          address = "134.99.210.131";
          prefixLength = 32;
          via = "134.99.147.33";
        };
      };
    };

    firewall = {
      checkReversePath = false;
      logRefusedConnections = true;
    };
  };

  virtualisation.vmware.guest.enable = true;

  teenix.bootconfig.enable = true;

  teenix.services.openssh.enable = true;

  teenix.config.defaultContainerNetworkId = "192.168";

  # Services
  teenix.persist.enable = true;

  teenix.services.traefik = {
    enable = true;

    letsencryptMail = "fscs@hhu.de";
  };

  teenix.services.node_exporter.enable = true;

  teenix.services.uptime-kuma = {
    enable = true;
    hostname = "uptime.dev.hhu-fscs.de";
  };

  teenix.services.ntfy = {
    enable = true;
    hostname = "ntfy.dev.hhu-fscs.de";
  };

  sops.secrets.verleihnix-root-passwd = {
    sopsFile = ../secrets/passwords.yml;
    neededForUsers = true;
  };

  # if this doesnt exist, traefik stops working (because sops templating refuses to work)
  sops.secrets.blub = {
    sopsFile = ../secrets/passwords.yml;
    key = "verleihnix-root-passwd";
  };

  users.users.root.hashedPasswordFile = config.sops.secrets.verleihnix-root-passwd.path;

  teenix.services.minecraft.enable = true;

  teenix.services.fscshhude = {
    enable = true;
    secretsFile = ../secrets/fscshhude.yml;
  };

  teenix.services.gatus = {
    enable = true;
    hostname = "status.dev.hhu-fscs.de";

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

  system.stateVersion = "23.11";
}
