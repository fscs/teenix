{ config, ... }:
{
  teenix.config.defaultContainerNetworkId = "192.18";

  teenix.services.collabora = {
    enable = true;
    hostname = "collabora.phynix-hhu.de";
    nextcloudHost = config.teenix.services.nextcloud.hostname;
  };

  teenix.services.helfendentool = {
    enable = true;
    hostname = "helfendentool.phynix-hhu.de";
    secretsFile = ../secrets/helfendentool_yaml;
    rabbitmqSecret = ../secrets/helfendtool_rabbitmq;
  };

  teenix.services.nextcloud = {
    enable = true;
    hostname = "nextcloud.phynix-hhu.de";
    secretsFile = ../secrets/nextcloud.yml;
    extraApps = [
      "calendar"
      "contacts"
      "deck"
      "files_automatedtagging"
      "files_retention"
      "forms"
      "groupfolders"
      "notify_push"
      "polls"
      "richdocuments"
      "sociallogin"
      "tasks"
    ];
  };

  teenix.services.fscshhude = {
    enable = true;
    secretsFile = ../secrets/fscshhude.yml;
  };

  teenix.services.sitzungsverwaltung = {
    enable = true;
    hostname = "sitzungen.hhu-fscs.de";
  };

  teenix.services.pretix = {
    enable = true;
    hostname = "pretix.phynix-hhu.de";
    email = "fscs@hhu.de";
  };

  teenix.services.mete = {
    enable = true;
    hostname = "mete.hhu-fscs.de";
    hostname-summary = "gorden-summary.hhu-fscs.de";
  };

  teenix.services.authentik = {
    enable = true;
    hostname = "auth.phynix-hhu.de";
    secretsFile = ../secrets/authentik.yml;
  };

  teenix.services.alloy = {
    enable = true;
    loki.exporterUrl = "${config.containers.prometheus.localAddress}:3100";
  };

  teenix.services.prometheus = {
    enable = true;
    hostnames = {
      prometheus = "prometheus.hhu-fscs.de";
      grafana = "grafana.hhu-fscs.de";
    };
    secretsFile = ../secrets/prometheus.yml;
  };

  teenix.services.discord-inphima-bot = {
    enable = true;
    secretsFile = ../secrets/discord-inphima-bot.yml;
  };

  teenix.services.inphimade = {
    enable = true;
    hostname = "inphima.de";
    secretsFile = ../secrets/inphimade/env;
    mariaEnvFile = ../secrets/inphimade/maria_env;
  };

  teenix.services.phynixhhude = {
    enable = true;
    hostname = "phynix-hhu.de";
    secretsFile = ../secrets/phynixhhude.yml;
  };

  teenix.services.fsnawide = {
    enable = true;
    hostname = "fsnawi.de";
    secretsFile = ../secrets/nawi/env;
    mariaEnvFile = ../secrets/nawi/maria_env;
  };

  teenix.services.freescout = {
    enable = true;
    hostname = "tickets.hhu-fscs.de";
    secretsFile = ../secrets/freescout/env;
    mariaEnvFile = ../secrets/freescout/maria_env;
  };

  teenix.services.campus-guesser-server = {
    enable = true;
    hostname = "campusguesser.phynix-hhu.de";
    secretsFile = ../secrets/campus-guesser-server.yml;
  };

  teenix.services.node_exporter = {
    enable = true;
  };

  teenix.services.gitlab-runner = {
    enable = true;
    secretsFile = ../secrets/gitlab_runner.yml;
  };

  teenix.services.vaultwarden = {
    enable = true;
    secretsFile = ../secrets/vaultwarden.yml;
    hostname = "vaultwarden.phynix-hhu.de";
  };

  teenix.services.ntfy = {
    enable = true;
    hostname = "ntfy.hhu-fscs.de";
  };

  teenix.services.matrix-intern-bot = {
    enable = false;
    secretsFile = ../secrets/matrixinternbot;
  };

  teenix.services.scanner = {
    enable = true;
    secretsFile = ../secrets/scanner.yml;
  };

  teenix.services.atticd = {
    enable = true;
    secretsFile = ../secrets/attic.yml;
    hostname = "attic.hhu-fscs.de";
  };

  teenix.services.docnix = {
    enable = true;
    hostname = "docnix.hhu-fscs.de";
  };

  teenix.services.matrix = {
    enable = true;
    secretsFile = ../secrets/matrix.yml;
    hostnames = rec {
      homeserver = "inphima.de";
      matrix = "matrix.${homeserver}";
      mas = "matrixauth.${homeserver}";
      hookshot = "hookshot.${homeserver}";
      sydent = "sydent.${homeserver}";
      element-web = "element.${homeserver}";
    };
  };

  teenix.services.bahn-monitor = {
    enable = true;
    hostname = "bahn.phynix-hhu.de";
  };

  teenix.services.crabfit = {
    enable = true;
    hostnames = rec {
      frontend = "crabfit.phynix-hhu.de";
      backend = "api.${frontend}";
    };
  };
}
