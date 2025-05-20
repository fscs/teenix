{
  lib,
  config,
  ...
}:
{
  imports = [ ./meta.nix ];

  options.teenix.services.prometheus = {
    enable = lib.mkEnableOption "prometheus";
    hostnames = {
      prometheus = lib.teenix.mkHostnameOption "prometheus";
      grafana = lib.teenix.mkHostnameOption "prometheus";
    };
    secretsFile = lib.teenix.mkSecretsFileOption "prometheus";
  };

  config =
    let
      cfg = config.teenix.services.prometheus;
    in
    lib.mkIf cfg.enable {
      teenix.services.traefik.httpServices = {
        prometheus = {
          router.rule = "Host(`${cfg.hostnames.prometheus}`)";
          router.middlewares = [ "authentik" ];
          servers = [ "http://${config.containers.prometheus.localAddress}:9090" ];
          healthCheck.enable = true;
        };

        grafana = {
          router.rule = "Host(`${cfg.hostnames.grafana}`)";
          servers = [ "http://${config.containers.prometheus.localAddress}:80" ];
          healthCheck = {
            enable = true;
            path = "/login";
          };
        };
      };

      sops.secrets.grafana2ntfy = {
        sopsFile = cfg.secretsFile;
        key = "grafana-2-ntfy-env";
        mode = "444";
      };

      teenix.containers.prometheus = {
        config = ./container.nix;

        networking = {
          useResolvConf = true;
          ports.tcp = [
            80
            3100
            9090
            9093
          ];
        };

        backup = false;

        mounts = {
          postgres.enable = true;

          data.enable = true;

          sops.secrets = [ "grafana2ntfy" ];

          extra.grafana-data = {
            mountPoint = config.containers.prometheus.config.services.grafana.dataDir;
            isReadOnly = false;
          };

          extra.loki-data = {
            mountPoint = config.containers.prometheus.config.services.loki.dataDir;
            isReadOnly = false;
          };
        };
      };
    };
}
