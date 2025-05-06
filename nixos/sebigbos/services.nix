{
  teenix.config.defaultContainerNetworkId = "10.0";

  teenix.persist.enable = true;

  teenix.services.traefik = {
    enable = true;

    letsencryptMail = "fscs@hhu.de";

    dashboard = {
      enable = true;
      url = "traefik.sebigbos.hhu-fscs.de";
    };
  };

  teenix.meta.ha.enable = true;

  teenix.ha.fscshhude = {
    hostname = "fscs.sebigbos.hhu-fscs.de";
    port = 8080;
  };
}
