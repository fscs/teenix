{
  inputs,
  host-config,
  ...
}:
{
  imports = [
    inputs.authentik-nix.nixosModules.default
  ];

  services.authentik = {
    enable = true;
    environmentFile = host-config.sops.templates.authentik.path;
    createDatabase = true;

    settings = {
      email = {
        host = "mail.hhu.de";
        port = 587;
        username = "noreply-fscs";
        use_tls = true;
        use_ssl = false;
        from = "noreply-fscs@hhu.de";
      };
      disable_startup_analytics = true;
      avatars = "initials";
    };

    nginx = {
      enable = true;
      enableACME = false;
      host = "localhost";
    };

  };

  system.stateVersion = "23.11";
}
