{
  lib,
  config,
  ...
}: {
  options.teenix.services.alloy = let
    t = lib.types;
  in {
    enable = lib.mkEnableOption "enable grafana alloy";
    loki = {
      exporterUrl = lib.mkOption {
        description = "loki url to export to";
        type = t.nonEmptyStr;
      };
      exporterName = lib.mkOption {
        type = t.nonEmptyStr;
        default = "loki_write";
      };
    };
    extraConfig = lib.mkOption {
      type = t.lines; 
    };
  };

  config = let
    cfg = config.teenix.services.alloy;
  in lib.mkIf cfg.enable {
    services.alloy.enable = true;

    teenix.services.alloy.extraConfig = lib.mkAfter ''
      loki.write "${cfg.loki.exporterName}" {
        endpoint {
          url ="http://${cfg.loki.exporterUrl}/loki/api/v1/push"
        }
      } 
    '';

    environment.etc."alloy/config.alloy".text = cfg.extraConfig;
  };
}
