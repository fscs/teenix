{
  lib,
  config,
  host-config,
  pkgs,
  pkgs-stable,
  inputs,
  ...
}:
{
  services.prometheus = {
    enable = true;
    stateDir = "prometheus";
    globalConfig.scrape_interval = "1s";
    retentionTime = "30d";
    scrapeConfigs = [
      {
        job_name = "traefik";
        metrics_path = "/metrics";
        static_configs = lib.singleton {
          targets = [
            "${host-config.containers.prometheus.hostAddress}:120"
          ];
        };
      }
      {
        job_name = "node_exporter";
        metrics_path = "/metrics";
        static_configs = lib.singleton {
          targets = [
            "teefax:9100"
          ];
        };
      }
      {
        job_name = "matrix";
        metrics_path = "/_synapse/metrics";
        static_configs = lib.singleton {
          targets = [
            "matrix.phynix-hhu.de"
          ];
        };
      }
    ];
  };

  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;

      server.http_listen_port = 3100;
      server.grpc_server_max_recv_msg_size = 8388608;

      common = {
        replication_factor = 1;
        path_prefix = config.services.loki.dataDir;

        ring = {
          instance_addr = "127.0.0.1";
          kvstore.store = "inmemory";
        };

        storage.filesystem = {
          chunks_directory = "${config.services.loki.dataDir}/chunks";
          rules_directory = "${config.services.loki.dataDir}/rules";
        };
      };

      schema_config.configs = lib.singleton {
        from = "2025-01-01";
        store = "tsdb";
        object_store = "filesystem";
        schema = "v13";
        index = {
          prefix = "index_";
          period = "24h";
        };
      };
    };
  };

  services.grafana = {
    package = pkgs-stable.grafana;
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
        http_port = 80;
        domain = "grafana.hhu-fscs.de";
      };
      "auth.generic_oauth" = {
        enabled = true;
        name = "Authentik";
        allow_sign_up = true;
        client_id = "hFGHZUCwQEL8BD8vzGoakVKIXwKHDiPgMQAwkC5g";
        scopes = [
          "openid"
          "email"
          "profile"
          "offline_access"
          "roles"
        ];
        email_attribute_path = "email";
        login_attribute_path = "preferred_username";
        name_attribute_path = "given_name";
        auth_url = "https://auth.phynix-hhu.de/application/o/authorize/";
        token_url = "https://auth.phynix-hhu.de/application/o/token/";
        api_url = "https://auth.phynix-hhu.de/application/o/userinfo/";
        role_attribute_path = "contains(groups[*], 'admin') && 'Admin' || 'Editor'";
      };

    };
  };

  systemd.services.grafana-to-ntfy = {
    after = [ "network.target" ];
    path = [ pkgs.bash ];
    script = "${lib.getExe inputs.grafana2ntfy.packages.${pkgs.stdenv.system}.default}";
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
      EnvironmentFile = host-config.sops.secrets.grafana2ntfy.path;
    };
    wantedBy = [ "multi-user.target" ];
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "grafana" ];
    ensureUsers = lib.singleton {
      name = "grafana";
      ensureDBOwnership = true;
    };
    authentication = lib.mkForce ''
      local all       all     trust
      host  all       all     all trust
    '';
  };

  system.stateVersion = "23.11";
}
