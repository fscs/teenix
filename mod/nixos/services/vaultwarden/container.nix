{
  lib,
  inputs,
  pkgs,
  host-config,
  ...
}:
{
  networking.hostName = "vaultwarden";

  services.vaultwarden = {
    enable = true;
    environmentFile = host-config.sops.secrets.vaultwarden.path;
    config = {
      DOMAIN = "https://vaultwarden.hhu-fscs.de";
      SIGNUPS_ALLOWED = false;
      ROCKET_ADDRESS = "0.0.0.0";
      ROCKET_PORT = 8222;

      ROCKET_LOG = "critical";

      SMTP_HOST = "mail.hhu.de";
      SMTP_PORT = 465;
      SMTP_SECURITY = "force_tls";

      SMTP_FROM = "noreply-fscs@hhu.de";
      SMTP_FROM_NAME = "FSCS Password Manager";
      SMTP_USERNAME = "noreply-fscs";
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
