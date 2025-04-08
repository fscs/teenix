{
  lib,
  config,
  ...
}:
{
  options.teenix.services.prometheus = {
    enable = lib.mkEnableOption "setup prometheus";
    hostname = lib.teenix.mkHostnameOption;
    grafanaHostname = lib.teenix.mkHostnameOption;
    secretsFile = lib.teenix.mkSecretsFileOption "prometheus";
  };

  config =
    let
      opts = config.teenix.services.prometheus;
    in
    lib.mkIf opts.enable {
      sops.secrets.grafana2ntfy = {
        sopsFile = opts.secretsFile;
        key = "grafana-2-ntfy-env";
        mode = "444";
      };

      teenix.services.traefik.services.prometheus = {
        router.rule = "Host(`${opts.hostname}`)";
        servers = [ "http://${config.containers.prometheus.localAddress}:9090" ];
        healthCheck.enable = true;
      };

      teenix.services.traefik.services.grafana = {
        router.rule = "Host(`${opts.grafanaHostname}`)";
        servers = [ "http://${config.containers.prometheus.localAddress}:80" ];
        healthCheck = {
          enable = true;
          path = "/login";
        };
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

        mounts = {
          postgres.enable = true;

          data.enable = true;

          sops.secrets = [
            config.sops.secrets.grafana2ntfy
          ];

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
