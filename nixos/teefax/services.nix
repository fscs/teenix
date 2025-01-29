{ config, ... }:
{
  teenix.services.collabora = {
    enable = true;
    hostname = "collabora.inphima.de";
    nextcloudHost = "nextcloud.inphima.de";
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
  };

  teenix.services.fscshhude = {
    enable = true;
    hostname = "hhu-fscs.de";
    secretsFile = ../secrets/fscshhude;
  };

  teenix.services.matrix = {
    enable = true;
    servername = "inphima.de";
    secretsFile = ../secrets/test_pwd;
    configFile = ../secrets/matrix_config;
    masSecrets = ../secrets/masconfig_yaml;
    hookshotSecrets = ../secrets/matrix-hookshot;
  };

  teenix.services.element-web = {
    enable = true;
    hostname = "element.inphima.de";
    matrixUrl = "inphima.de";
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

  teenix.services.passbolt = {
    enable = false;
    hostname = "passbolt.hhu-fscs.de";
    secretsFile = ../secrets/passbolt/env;
    mariaEnvFile = ../secrets/passbolt/maria_env;
  };

  teenix.services.discord-intern-bot = {
    enable = true;
    secretsFile = ../secrets/discord-intern-bot.yml;
  };

  teenix.services.traefik.services.onlyoffice = config.nix-tun.services.traefik.services.onlyoffice;

  nix-tun.services.containers.onlyoffice = {
    enable = true;
    hostname = "office.inphima.de";
    jwtSecretFile = ../secrets/onlyoffice;
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

  teenix.services.sydent = {
    enable = true;
    hostname = "sydent.inphima.de";
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

  sops.secrets.scanner-pass = {
    format = "binary";
    sopsFile = ../secrets/scanner_pwd;
  };

  services.vsftpd = {
    enable = true;
    localUsers = true;
    writeEnable = true;
    allowWriteableChroot = true;
    localRoot = "/persist/scanner";
    extraConfig = ''
      listen_port=2121
      pasv_min_port=3000
      pasv_max_port=3100
      # rsa_cert_file=/home/scanner/vsftpd.pem
      # rsa_private_key_file=/home/scanner/vsftpd.pem
      ssl_enable=YES
      anonymous_enable=NO
      local_umask=011
      file_open_mode=0777
    '';
  };
}
