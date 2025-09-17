{
  lib,
  config,
  ...
}:
let
  cfg = config.teenix.services.n8n;
in
{
  imports = [ ./meta.nix ];

  options.teenix.services.n8n = {
    enable = lib.mkEnableOption "n8n";
    hostname = lib.teenix.mkHostnameOption "n8n";
    secretsFile = lib.teenix.mkSecretsFileOption "n8n";
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "n8n"
      ];

    teenix.services.traefik.httpServices.n8n = {
      router.rule = "Host(`${cfg.hostname}`)";
      servers = [
        "http://${config.containers.n8n.localAddress}:${toString config.containers.n8n.config.services.n8n.settings.port}"
      ];
    };

    teenix.containers.n8n = {
      config = ./container.nix;

      networking = {
        useResolvConf = true;
        ports.tcp = [ config.containers.n8n.config.services.n8n.settings.port ];
      };

      mounts.data.enable = true;
    };
  };
}
