{
  pkgs,
  pkgs-master,
  host-config,
  outputs,
  ...
}:
{
  services.vaultwarden = {
    enable = true;
    package = pkgs-master.vaultwarden;
    webVaultPackage = outputs.packages.${pkgs.stdenv.system}.voltwarden-webvault;
    environmentFile = host-config.sops.templates.vaultwarden.path;
    config = {
      DOMAIN = "https://${host-config.teenix.services.vaultwarden.hostname}";
      SIGNUPS_ALLOWED = false;
      EXPERIMENTAL_CLIENT_FEATURE_FLAGS = "autofill-overlay,autofill-v2,browser-fileless-import,extension-refresh,fido2-vault-credentials,ssh-key-vault-item,ssh-agent";

      ROCKET_ADDRESS = "0.0.0.0";
      ROCKET_PORT = 8222;
      ROCKET_LOG = "critical";

      SMTP_HOST = "mail.hhu.de";
      SMTP_PORT = 465;
      SMTP_SECURITY = "force_tls";
      SMTP_FROM = "noreply-fscs@hhu.de";
      SMTP_FROM_NAME = "PhyNIx Password Manager";
      SMTP_USERNAME = "noreply-fscs";
    };
  };

  system.stateVersion = "24.11";
}
