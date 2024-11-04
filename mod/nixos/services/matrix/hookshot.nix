{ pkgs
, lib
, config
, ...
}: {
  options.teenix.services.matrix-hookshot = {
    enable = lib.mkEnableOption "Enable Matrix Hookshot Service";
    secretFile = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = lib.mkIf config.teenix.services.matrix-hookshot.enable {
    services.matrix-hookshot = {
      enable = true;
      registrationFile = config.teenix.services.matrix-hookshot.secretFile;
      settings = {
        bridge = {
          domain = "inphima.de";
          url = "http://localhost:8008";
          mediaUrl = "https://inphima.de";
          port = 9993;
          bindAddress = "0.0.0.0";
        };
        listeners = [
          {
            bindAddress = "0.0.0.0";
            port = 9000;
            resources = lib.singleton "webhooks";
          }
        ];
        generic = {
          enabled = true;
          outbound = false;
          enableHttpGet = false;
          urlPrefix = "https://inphima.de/webhooks";
          allowJsTransformationFunctions = false;
          waitForComplete = false;
        };
      };
    };
  };
}
