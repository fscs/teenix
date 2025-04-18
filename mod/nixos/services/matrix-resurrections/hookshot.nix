{
  lib,
  config,
  host-config,
  ...
}:
{
  options.teenix.services.matrix-hookshot = {
    enable = lib.mkEnableOption "Enable Matrix Hookshot Service";
    registrationSettings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      description = "ugly hack to generate the template outside of the container, eww";
    };
  };

  config = lib.mkIf config.teenix.services.matrix-hookshot.enable {
    teenix.services.matrix-hookshot.registrationSettings = {
      id = "matrix-hookshot";

      as_token = host-config.sops.placeholder.matrix-hookshot-as-token;
      hs_token = host-config.sops.placeholder.matrix-hookshot-hs-token;

      sender_localpart = "hookshot";
      url = "https://localhost:9993";
      rate_limited = false;

      namespaces = {
        rooms = []; 
        users = lib.singleton {
          regex = "@_webhooks_.*:inphima.de";
          exclusive = true;
        };
      };
    };
    
    services.matrix-hookshot = {
      enable = true;
      registrationFile = host-config.sops.templates.matrix-hookshot-registration-file.path;
      settings = {
        bridge = {
          domain = host-config.teenix.services.matrix.hostnames.homeserver;
          url = "http://localhost:8008";
          mediaUrl = "https://${host-config.teenix.services.matrix.hostnames.homeserver}";
          port = 9993;
          bindAddress = "0.0.0.0";
        };

        listeners = lib.singleton {
          bindAddress = "0.0.0.0";
          port = 9000;
          resources = [ "webhooks" ];
        };

        generic = {
          enabled = true;
          outbound = false;
          enableHttpGet = false;
          urlPrefix = "https://${host-config.teenix.services.matrix.hostnames.homeserver}/webhooks";
          allowJsTransformationFunctions = false;
          waitForComplete = false;
        };
      };
    };
  };
}
