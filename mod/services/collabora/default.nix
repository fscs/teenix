{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./meta.nix ];

  options.teenix.services.collabora = {
    enable = lib.mkEnableOption "collabora";
    hostname = lib.teenix.mkHostnameOption "collabora";
    nextcloudHost = lib.mkOption {
      type = lib.types.str;
      description = "Url of the connected NextCloud Instance";
    };
  };

  config =
    let
      cfg = config.teenix.services.collabora;
    in
    lib.mkIf cfg.enable {
      teenix.services.traefik.httpServices.collabora = {
        router.rule = "Host(`${cfg.hostname}`)";
        healthCheck.enable = true;

        servers = [
          "http://${config.containers.collabora.localAddress}:${toString config.containers.collabora.config.services.collabora-online.port}"
        ];
      };

      teenix.containers.collabora = {
        config = {
          systemd.services.coolwsd.environment.server_name = config.teenix.services.collabora.hostname;
          services.collabora-online = {
            enable = true;
            package = pkgs.collabora-online;
            aliasGroups = lib.singleton {
              host = "https://${config.teenix.services.collabora.nextcloudHost}:443";
            };
            settings = {
              net.post_allow.host = "192\.[0-9]+\.[0-9]+\.[0-9]+";
              net.proto = "IPv4";
              ssl.enable = false;
              ssl.termination = true;
              ssl_verification = false;
              remote_font_config.url = "https://${cfg.nextcloudHost}/apps/richdocuments/settings/fonts.json";
              security.capabilities = false;
            };
          };

          system.stateVersion = "24.11";
        };

        networking = {
          useResolvConf = true;
          ports.tcp = [ config.containers.collabora.config.services.collabora-online.port ];
        };
      };
    };
}
