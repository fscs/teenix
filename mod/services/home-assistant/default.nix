{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.teenix.services.home-assistant;

  secrets = [
    "home-assistant-oauth-client-secret"
    "home-assistant-matrix-username"
    "home-assistant-matrix-password"
    "home-assistant-matrix-roomid"
    "home-assistant-alarm-code"
  ];

  # one of the secrets contains an @, so we need to redefine the yaml generator
  # since it doesnt know about it because of templating, it also cannot escape it automatically
  yaml_generate =
    name: value:
    pkgs.runCommand name
      {
        nativeBuildInputs = [ pkgs.remarshal_0_17 ];
        value = builtins.toJSON value;
        passAsFile = [ "value" ];
        preferLocalBuild = true;
      }
      ''
        json2yaml --yaml-style \" "$valuePath" "$out"
      '';
in
{
  imports = [ ./meta.nix ];

  options.teenix.services.home-assistant = {
    enable = lib.mkEnableOption "home-assistant";
    hostname = lib.teenix.mkHostnameOption "home-assistant";
    secretsFile = lib.teenix.mkSecretsFileOption "home-assistant";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = lib.genAttrs secrets (name: {
      sopsFile = cfg.secretsFile;
      key = lib.removePrefix "home-assistant-" name;
    });

    sops.templates.home-assistant-secrets = {
      mode = "0444";
      file = yaml_generate "secrets.yml" (lib.genAttrs secrets (name: config.sops.placeholder.${name}));
      restartUnits = [ "container@home-assistant.service" ];
    };

    teenix.services.traefik.httpServices.home-assistant = {
      router.rule = "Host(`${cfg.hostname}`)";
      servers = [
        "http://${config.containers.home-assistant.localAddress}:${toString config.containers.home-assistant.config.services.home-assistant.config.http.server_port}"
      ];
    };

    teenix.containers.home-assistant = {
      config = ./container.nix;

      extraConfig.interfaces = [ "tailscale0" ];

      networking = {
        useResolvConf = true;
        ports.tcp = [
          config.containers.home-assistant.config.services.home-assistant.config.http.server_port
        ];
      };

      mounts = {
        data = {
          enable = true;
          name = "hass";
        };

        extra.secrets = {
          hostPath = config.sops.templates.home-assistant-secrets.path;
          mountPoint = "${config.containers.home-assistant.config.services.home-assistant.configDir}/secrets.yaml";
        };
      };
    };
  };
}
