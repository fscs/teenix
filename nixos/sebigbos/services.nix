{ ... }:
{
  teenix.config.defaultContainerNetworkId = "10.10";

  teenix.services.traefik = {
    enable = true;
    letsencryptMail = "fscs@hhu.de";
  };

  teenix.services.home-assistant = {
    enable = true;
    hostname = "hatest.hhu-fscs.de";
    secretsFile = ../secrets/home-assistant.yml;
  };

  teenix.services.mosquitto = {
    enable = true;
    hostname = "mqtt.hhu-fscs.de";
    secretsFile = ../secrets/mosquitto.yml;
  };
}
