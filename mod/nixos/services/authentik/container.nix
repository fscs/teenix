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

  services.nginx = {
    virtualHosts."localhost".locations."/outpost.goauthentik.io" = {
      recommendedProxySettings = false;
      extraConfig = ''
        proxy_pass http://${host-config.containers.authentik.localAddress}:9000/outpost.goauthentik.io;
        proxy_set_header        Host $host;
        proxy_set_header        X-Real-IP $remote_addr;
        proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header        X-Forwarded-Proto $scheme;
      '';
    };
  };

  system.stateVersion = "23.11";
}
