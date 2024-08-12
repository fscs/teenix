{ lib
, host-config
, ...
}:
let
  opts = host-config.teenix.services.keycloak;
in
{
  services.keycloak = {
    enable = true;
    settings = {
      hostname = opts.hostname;
      proxy = "edge";
      http-enabled = true;
    };
    database = {
      passwordFile = host-config.sops.secrets.keycloak_pass.path;

      type = "postgresql";
      createLocally = true;

      username = "keycloak";
    };
  };

  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 80 ];
    };
    # Use systemd-resolved inside the container
    # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
    useHostResolvConf = lib.mkForce false;
  };

  services.resolved.enable = true;

  system.stateVersion = "23.11";
}
