{ lib
, host-config
, pkgs
, ...
}:
let
  opts = host-config.teenix.services.prometheus;
in
{
  networking.hostName = "prometheus";
  networking.nameservers = [ "134.99.154.201" "134.99.154.228" ];

  services.prometheus = {
    enable = true;
    globalConfig.scrape_interval = "10s";
    ruleFiles = [ ./prometheus_rules.yaml ];
    alertmanager = {
      enable = true;
      webExternalUrl = "https://${opts.alertmanagerURL}";
      environmentFile = host-config.sops.secrets.prometheus_env.path;
      checkConfig = false;
      configText = ''
        route:
          group_by: ['alertname', 'job']

          group_wait: 10s
          group_interval: 10s
          repeat_interval: 3h

          receiver: discord

        receivers:
        - name: discord
          discord_configs:
          - message: |
              {{ range .Alerts.Firing }}
              - {{ .Labels.service }} {{ end }}
              {{ if and (gt (len .Alerts.Resolved) 0) (gt (len .Alerts.Firing) 0) }}
              ### Traefik Service is back up
              {{ end }}
              {{ range .Alerts.Resolved }}
              - {{ .Labels.service }} {{ end }}
            title: 'Traefik Service is {{ if gt (len .Alerts.Firing) 0 }}down {{ else }}back up {{ end }}'
            send_resolved: true
            webhook_url: $ENVIRONMENT ''${discord_url}
      '';
    };
    alertmanagers = [
      {
        scheme = "http";
        path_prefix = "/";
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
      {
        job_name = "node_exporter";
        metrics_path = "/metrics";
        static_configs = [
          {
            targets = [
              "localhost:9100"
            ];
          }
        ];
      }
    ];
  };

  users.users.node_exporter = {
    uid = 1033;
    home = "/home/node_exporter";
    group = "users";
    shell = pkgs.bash;
    isNormalUser = true;
  };

  systemd.services.node_exporter-serve = {
    description = "Start node exporter";
    after = [ "network.target" ];
    path = [ pkgs.bash ];
    serviceConfig = {
      Type = "exec";
      User = "node_exporter";
      WorkingDirectory = "/home/node_exporter";
      ExecStart = "${pkgs.prometheus-node-exporter}/bin/node_exporter";
      Restart = "always";
      RestartSec = 5;
    };
    wantedBy = [ "multi-user.target" ];
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
    authentication = lib.mkOverride 10 ''
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
}
