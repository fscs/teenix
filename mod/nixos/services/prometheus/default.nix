{ lib
, config
, pkgs-stable
, inputs
, ...
}:
{
  options.teenix.services.prometheus = {
    enable = lib.mkEnableOption "setup prometheus";
    hostname = lib.teenix.mkHostnameOption;
    secretsFile = lib.teenix.mkSecretsFileOption "prometheus";
    ntfySecret = lib.teenix.mkSecretsFileOption "grafana2ntfy";
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
      sops.secrets.prometheus_env = {
        sopsFile = opts.secretsFile;
        format = "binary";
        mode = "444";
      };

      sops.secrets.grafana2ntfy = {
        sopsFile = opts.ntfySecret;
        format = "binary";
        mode = "444";
      };

      nix-tun.storage.persist.subvolumes."grafana".directories = {
        "/postgres" = {
          owner = "${builtins.toString config.containers.prometheus.config.users.users.postgres.uid}";
          mode = "0700";
        };
        "/prometheus" = {
          owner = "${builtins.toString config.containers.prometheus.config.users.users.prometheus.uid}";
          mode = "0700";
        };
        "/grafana" = {
          owner = "${builtins.toString config.containers.prometheus.config.users.users.grafana.uid}";
          mode = "0700";
        };
      };

      teenix.services.traefik.services."prometheus" = {
        router.rule = "Host(`${opts.hostname}`)";
        servers = [ "http://${config.containers.prometheus.config.networking.hostName}:9090" ];
        healthCheck.enable = true;
      };

      teenix.services.traefik.services."grafana" = {
        router.rule = "Host(`${opts.grafanaHostname}`)";
        servers = [ "http://${config.containers.prometheus.config.networking.hostName}:80" ];
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
          "grafana-2-ntfy" = {
            hostPath = config.sops.secrets.grafana2ntfy.path;
            mountPoint = config.sops.secrets.grafana2ntfy.path;
          };
          "prometheus" = {
            hostPath = "${config.nix-tun.storage.persist.path}/grafana/prometheus";
            mountPoint = "/var/lib/prometheus2";
            isReadOnly = false;
          };
          "env" = {
            hostPath = config.sops.secrets.prometheus_env.path;
            mountPoint = config.sops.secrets.prometheus_env.path;
          };
          "logs" = {
            hostPath = "/var/log";
            mountPoint = "/var/log/other";
          };
        };

        specialArgs = {
          inherit inputs pkgs-stable;
          host-config = config;
        };

        config = import ./container.nix;
      };
    };
}
