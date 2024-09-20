{ config, lib, ... }: {

  options.teenix.services.collabora = {
    enable = lib.mkEnableOption "Enable collabora";
    hostname = lib.mkOption {
      type = lib.types.str;
    };
    nextcloudHost = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = {

    virtualisation.oci-containers.containers."collabora" = {
      image = "collabora/code:latest";
      environment = {
        aliasgroup1 = "https://${config.teenix.services.collabora.nextcloudHost}:443";
        server_name = "${config.teenix.services.collabora.hostname}";
        extra_params = "--o:ssl.enable=true --o:remote_font_config.url=https://nextcloud.inphima.de/apps/richdocuments/settings/fonts.json";
      };
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.collabora.entrypoints" = "websecure";
        "traefik.http.routers.collabora.rule" = "Host(`${config.teenix.services.collabora.hostname}`)";
        "traefik.http.routers.collabora.tls" = "true";
        "traefik.http.routers.collabora.tls.certresolver" = "letsencrypt";
        "traefik.http.services.collabora.loadbalancer.server.port" = "9980";
        "traefik.http.services.collabora.loadbalancer.server.scheme" = "https";
      };
    };
  };
}
