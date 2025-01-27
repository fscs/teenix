{
  pkgs-master,
  host-config,
  ...
}:
{
  users.users.vaultwarden.uid = 99;

  services.vaultwarden = {
    enable = true;
    package = pkgs-master.vaultwarden;
    webVaultPackage = pkgs-master.voltwarden-webvault;
    environmentFile = host-config.sops.templates.vaultwarden.path;
    config = {
      DOMAIN = "https://${host-config.teenix.services.vaultwarden.hostname}";
      SIGNUPS_ALLOWED = false;
      ROCKET_ADDRESS = "0.0.0.0";
      ROCKET_PORT = 8222;

      ROCKET_LOG = "critical";

      SMTP_HOST = "mail.hhu.de";
      SMTP_PORT = 465;
      SMTP_SECURITY = "force_tls";

      SMTP_FROM = "noreply-fscs@hhu.de";
      SMTP_FROM_NAME = "INPhiMa Password Manager";
      SMTP_USERNAME = "noreply-fscs";
      EXPERIMENTAL_CLIENT_FEATURE_FLAGS = "autofill-overlay,autofill-v2,browser-fileless-import,extension-refresh,fido2-vault-credentials,ssh-key-vault-item,ssh-agent";
    };
  };

  system.stateVersion = "23.11";
}
