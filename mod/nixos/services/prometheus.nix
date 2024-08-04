{ lib
, config
, pkgs
, ...
}: {
  options.teenix.services.prometheus = {
    enable = lib.mkEnableOption "setup prometheus";
    hostname = lib.mkOption {
      type = lib.types.str;
    };
    grafanaHostname = lib.mkOption {
      type = lib.types.str;
    };
    alertmanagerURL = lib.mkOption {
      type = lib.types.str;
    };
  };

  config =
    let
      opts = config.teenix.services.prometheus;
    in
    lib.mkIf opts.enable {
      nix-tun.storage.persist.subvolumes."grafana".directories = {
        "/postgres" = {
          owner = "${builtins.toString config.containers.prometheus.config.users.users.postgres.uid}";
          mode = "0700";
        };
      };

      teenix.services.traefik.services."prometheus" = {
        router.rule = "Host(`${opts.hostname}`)";
        servers = [ "http://${config.containers.prometheus.config.networking.hostName}:9090" ];
      };

      teenix.services.traefik.services."grafana" = {
        router.rule = "Host(`${opts.grafanaHostname}`)";
        servers = [ "http://${config.containers.prometheus.config.networking.hostName}:3000" ];
      };

      teenix.services.traefik.services."alerts" = {
        router.rule = "Host(`${opts.alertmanagerURL}`)";
        servers = [ "http://${config.containers.prometheus.config.networking.hostName}:9093" ];
      };

      containers.prometheus = {
        ephemeral = true;
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.109.10";
        localAddress = "192.168.109.11";

        bindMounts = {
          "db" = {
            hostPath = "${config.nix-tun.storage.persist.path}/grafana/postgres";
            mountPoint = "/var/lib/postgres";
            isReadOnly = false;
          };
          "grafana" = {
            hostPath = "${config.nix-tun.storage.persist.path}/grafana/grafana";
            mountPoint = "/var/lib/grafana";
            isReadOnly = false;
          };
          "prometheus" = {
            hostPath = "${config.nix-tun.storage.persist.path}/grafana/prometheus";
            mountPoint = "/var/lib/prometheus2";
            isReadOnly = false;
          };
        };

        config = { lib, ... }: {
          networking.hostName = "prometheus";
          networking.nameservers = [ "9.9.9.9" ];

          services.prometheus = {
            enable = true;
            globalConfig.scrape_interval = "10s";
            alertmanager = {
              enable = true;
              webExternalUrl = "https://${opts.alertmanagerURL}";
              configText = ''
                route:
                  group_by: ['alertname', 'job']

                  group_wait: 30s
                  group_interval: 5m
                  repeat_interval: 3h

                  receiver: discord

                receivers:
                - name: discord
                  discord_configs:
                  - webhook_url: "https://discord.com/api/webhooks/1268160361295511726/KOsvdpA4BzSYVNL2OQFQtfntBDloK0VAsSe4jzp9LHcuxuIXt7Osk3699MKDLyBeH3d4"
              '';
            };
            alertmanagers = [
              {
                scheme = "https";
                path_prefix = "/alertmanager";
                static_configs = [
                  {
                    targets = [
                      "localhost:9093"
                    ];
                  }
                ];
              }
            ];
            scrapeConfigs = [
              {
                job_name = "traefik";
                metrics_path = "/metrics";
                static_configs = [
                  {
                    targets = [
                      "192.168.109.10:120"
                    ];
                  }
                ];
              }
            ];
          };

          services.grafana = {
            enable = true;
            settings = {
              database = {
                type = "postgres";
                user = "grafana";
                name = "grafana";
                host = "localhost:5432";
              };
              server = {
                http_addr = "0.0.0.0";
                http_port = 3000;
                domain = "${opts.hostname}";
              };
            };
          };

          services.postgresql = {
            enable = true;
            ensureDatabases = [
              "grafana"
            ];
            ensureUsers = [
              {
                name = "grafana";
                ensureDBOwnership = true;
              }
            ];
            dataDir = "/var/lib/postgres";
            authentication = pkgs.lib.mkOverride 10 ''
              local all       all     trust
              host  all       all     all trust
            '';
          };

          networking = {
            firewall = {
              enable = true;
              allowedTCPPorts = [ 9090 3000 9093 ];
            };
            # Use systemd-resolved inside the container
            # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
            useHostResolvConf = lib.mkForce false;
          };

          system.stateVersion = "23.11";
        };
      };
    };
}
