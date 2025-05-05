{
  lib,
  pkgs,
  config,
  ...
}:
let
  t = lib.types;
  cfg = config.teenix.services.gatus;

  yaml = pkgs.formats.yaml { };

  endpointType = t.submodule {
    options = {
      name = lib.mkOption {
        description = "name of this service";
        type = t.nonEmptyStr;
      };
      url = lib.mkOption {
        description = "url to healthcheck";
        type = t.nonEmptyStr;
      };
      status = lib.mkOption {
        description = "returned status code to consider the service healthy";
        type = t.nullOr (t.ints.between 0 599);
        default = 200;
      };
      interval = lib.mkOption {
        description = "interval to healthcheck on";
        type = t.nonEmptyStr;
        defaultText = lib.literalExpression "cfg.interval";
        default = cfg.interval;
      };
      extraConfig = lib.mkOption {
        type = yaml.type;
        default = { };
      };
    };
  };

  groupType = t.submodule {
    options = {
      name = lib.mkOption {
        description = "display name of this group";
        type = t.nonEmptyStr;
      };
      endpoints = lib.mkOption {
        description = "endpoints of this group";
        type = t.attrsOf endpointType;
      };

    };
  };
in
{
  imports = [ ./meta.nix ];

  options.teenix.services.gatus = {
    enable = lib.mkEnableOption "gatus, a status page";
    hostname = lib.teenix.mkHostnameOption "gatus";

    interval = lib.mkOption {
      description = "default interval to healthcheck on";
      type = t.nonEmptyStr;
      default = "5m";
    };

    groups = lib.mkOption {
      description = "groups of healthchecks";
      type = t.attrsOf groupType;
    };
  };

  config = lib.mkIf cfg.enable {
    teenix.services.traefik.httpServices.gatus = {
      router.rule = "Host(`${cfg.hostname}`)";
      servers = [
        "http://${config.containers.gatus.localAddress}:${toString config.containers.gatus.config.services.gatus.settings.web.port}"
      ];
    };

    teenix.containers.gatus = {
      config = ./container.nix;

      networking = {
        useResolvConf = true;
        ports.tcp = [
          config.containers.gatus.config.services.gatus.settings.web.port
        ];
      };

      mounts.data.enable = true;
    };
  };
}
