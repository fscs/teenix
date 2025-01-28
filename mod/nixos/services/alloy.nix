{
  lib,
  config,
  ...
}:
{
  options.teenix.services.alloy =
    let
      t = lib.types;
    in
    {
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

  config =
    let
      cfg = config.teenix.services.alloy;
    in
    lib.mkIf cfg.enable {
      services.alloy = {
        enable = true;
        extraFlags = [ "--disable-reporting" ];
      };

      teenix.services.alloy.extraConfig = ''
        loki.write "${cfg.loki.exporterName}" {
          endpoint {
            url ="http://${cfg.loki.exporterUrl}/loki/api/v1/push"
          }
        } 

        loki.relabel "nixos_container_journal" {
          forward_to = []

          rule {
            source_labels = ["__journal__systemd_unit"]
            target_label  = "unit"
          }
        }

        ${lib.concatStringsSep "\n" (
          lib.imap0 (i: containerName: ''
            // ${containerName}
            loki.source.journal "container_${toString i}_journal"  {
              path          = "/var/log/containers/${containerName}"
              forward_to    = [ loki.write.${config.teenix.services.alloy.loki.exporterName}.receiver ]
              relabel_rules = loki.relabel.nixos_container_journal.rules
              labels        = { container = "${containerName}"}
            }         
          '') (lib.attrNames config.teenix.containers)
        )}

      '';

      environment.etc."alloy/config.alloy".text = cfg.extraConfig;
    };
}
