{ lib
, inputs
, host-config
, ...
}: {
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

  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 80 9443 ];
    };
    # Use systemd-resolved inside the container
    # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
    useHostResolvConf = lib.mkForce false;
  };

  services.resolved.enable = true;

  system.stateVersion = "23.11";
}
