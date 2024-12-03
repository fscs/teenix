{
  lib,
  inputs,
  host-config,
  ...
}:
{
  imports = [
    inputs.authentik-nix.nixosModules.default
  ];

  networking.hostName = "authentik";

  services.authentik = {
    enable = true;
    environmentFile = host-config.sops.secrets.authentik_env.path;
    createDatabase = true;

    settings = {
      email = {
        host = "mail.hhu.de";
        port = 587;
        username = "fscs";
        use_tls = true;
        use_ssl = false;
        from = "fscs@hhu.de";
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
        proxy_pass http://localhost:9000/outpost.goauthentik.io;
        proxy_set_header        Host $host;
        proxy_set_header        X-Real-IP $remote_addr;
        proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header        X-Forwarded-Proto $scheme;
      '';
    };
  };

  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [
        80
        9443
        9000
      ];
    };
    # Use systemd-resolved inside the container
    # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
    useHostResolvConf = lib.mkForce false;
  };

  services.resolved.enable = true;

  system.stateVersion = "23.11";
}
