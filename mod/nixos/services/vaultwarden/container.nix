{
  lib,
  inputs,
  pkgs,
  pkgs-master,
  host-config,
  ...
}:
{
  networking.hostName = "vaultwarden";

  services.vaultwarden = {
    enable = true;
    package = pkgs-master.vaultwarden;
    webVaultPackage = pkgs-master.voltwarden-webvault;
    environmentFile = host-config.sops.secrets.vaultwarden.path;
    config = {
      DOMAIN = "https://vaultwarden.inphima.de";
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

  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 8222 ];
    };
    # Use systemd-resolved inside the container
    # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
    useHostResolvConf = lib.mkForce false;
  };

  services.resolved.enable = true;

  system.stateVersion = "23.11";
}
