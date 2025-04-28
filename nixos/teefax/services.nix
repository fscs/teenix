{ config, ... }:
{
  teenix.services.collabora = {
    enable = true;
    hostname = "collabora.inphima.de";
    nextcloudHost = config.teenix.services.nextcloud.hostname;
  };

  teenix.services.helfendentool = {
    enable = true;
    hostname = "helfendentool.inphima.de";
    secretsFile = ../secrets/helfendentool_yaml;
    rabbitmqSecret = ../secrets/helfendtool_rabbitmq;
  };

  teenix.services.nextcloud = {
    enable = true;
    hostname = "nextcloud.inphima.de";
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
    hostname = "pretix.inphima.de";
    email = "fscs@hhu.de";
  };

  teenix.services.mete = {
    enable = true;
    hostname = "mete.hhu-fscs.de";
    hostname-summary = "gorden-summary.hhu-fscs.de";
  };

  teenix.services.authentik = {
    enable = true;
    hostname = "auth.inphima.de";
    secretsFile = ../secrets/authentik.yml;
  };

  teenix.services.alloy = {
    enable = true;
    loki.exporterUrl = "${config.containers.prometheus.localAddress}:3100";
  };

  teenix.services.prometheus = {
    enable = true;
    hostname = "prometheus.hhu-fscs.de";
    grafanaHostname = "grafana.hhu-fscs.de";
    secretsFile = ../secrets/prometheus.yml;
  };

  teenix.services.discord-intern-bot = {
    enable = true;
    secretsFile = ../secrets/discord-intern-bot.yml;
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

  teenix.services.nawi = {
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
    hostname = "campusguesser.inphima.de";
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
    hostname = "vaultwarden.inphima.de";
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

  teenix.services.rally = {
    enable = true;
    hostname = "doodle.inphima.de";
    secretsFile = ../secrets/rally/env;
    postgresEnvFile = ../secrets/rally/mariaEnv;
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
    hostname = "bahn.inphima.de";
  };

  teenix.services.crabfit = {
    enable = true;
    hostnames = rec {
      frontend = "crabfit.inphima.de";
      backend = "api.${frontend}";
    };
  };
}
