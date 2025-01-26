{
  lib,
  config,
  ...
}:
{
  options.teenix.services.vaultwarden = {
    enable = lib.mkEnableOption "setup vaultwarden";
    secretsFile = lib.teenix.mkSecretsFileOption "vaultwarden";
    hostname = lib.teenix.mkHostnameOption;
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
          mode = "444";
        };
        secrets.vaultwarden-smtp-password = {
          sopsFile = opts.secretsFile;
          key = "smtp-password";
          mode = "444";
        };

        templates.vaultwarden.content = ''
          ADMIN_TOKEN=${config.sops.placeholder.vaultwarden-admin-token}
          SMTP_PASSWORD=${config.sops.placeholder.vaultwarden-smtp-password}
        '';
      };

      teenix.services.traefik.services.vaultwarden = {
        router.rule = "Host(`${opts.hostname}`)";
        healthCheck.enable = true;
        servers = [ "http://${config.containers.vaultwarden.config.networking.hostName}:8222" ];
      };

      teenix.containers.vaultwarden = {
        config = ./container.nix;
        networking.useResolvConf = true;
        networking.ports.tcp = [ 8222 ];

        mounts.logs.paths = [ "vaultwarden" ];

        mounts.sops = [
          config.sops.templates.vaultwarden
        ];

        mounts.data.enable = true;
        mounts.data.name = "bitwarden_rs";
        mounts.data.ownerUid = config.containers.vaultwarden.config.users.users.vaultwarden.uid;
      };
    };
}
