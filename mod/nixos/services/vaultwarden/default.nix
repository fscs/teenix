{
  lib,
  config,
  ...
}:
{
  imports = [ ./meta.nix ];

  options.teenix.services.vaultwarden = {
    enable = lib.mkEnableOption "vaultwarden";
    secretsFile = lib.teenix.mkSecretsFileOption "vaultwarden";
    hostname = lib.teenix.mkHostnameOption "vaultwarden";
  };

  config =
    let
      opts = config.teenix.services.vaultwarden;
    in
    lib.mkIf opts.enable {
      sops = {
        secrets.vaultwarden-admin-token = {
          sopsFile = opts.secretsFile;
          key = "admin-token";
        };
        secrets.vaultwarden-smtp-password = {
          sopsFile = opts.secretsFile;
          key = "smtp-password";
        };

        templates.vaultwarden.content = ''
          ADMIN_TOKEN=${config.sops.placeholder.vaultwarden-admin-token}
          SMTP_PASSWORD=${config.sops.placeholder.vaultwarden-smtp-password}
        '';
      };

      teenix.services.traefik.httpServices.vaultwarden = {
        router.rule = "Host(`${opts.hostname}`)";
        healthCheck.enable = true;
        servers = [ "http://${config.containers.vaultwarden.localAddress}:8222" ];
      };

      teenix.containers.vaultwarden = {
        config = ./container.nix;

        networking = {
          useResolvConf = true;
          ports.tcp = [ 8222 ];
        };

        mounts = {
          sops.templates = [ "vaultwarden" ];

          data.enable = true;
        };
      };
    };
}
