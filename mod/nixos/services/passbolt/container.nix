{ lib
, host-config
, inputs
, ...
}:
let
  opts = host-config.teenix.services.passbolt;
in
{
  users.users."docker" = {
    isNormalUser = true;
    extraGroups = [ "docker" "wheel" ];
  };
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      passbolt = {
        image = "passbolt/passbolt";
        user = "1000";
        environmentFiles = [ host-config.sops.secrets.passbolt.path ];
        ports = [ "8080:8080" ];
        environment = {
          DATASOURCES_DEFAULT_HOST = "mariadb";
          DATASOURCES_DEFAULT_USERNAME = "passbolt";
          DATASOURCES_DEFAULT_DATABASE = "passbolt";
          DATASOURCES_DEFAULT_PORT = "3306";
          DATASOURCES_QUOTE_IDENTIFIER = "true";
          APP_FULL_BASE_URL = "https://passbolt.fscs-hhu.de";
          EMAIL_DEFAULT_FROM = "fscs@hhu.de";
          EMAIL_TRANSPORT_DEFAULT_TLS = "true";
          PASSBOLT_KEY_EMAIL = "fscs@hhu.de";
        };
      };
      mariadb = {
        image = "mariadb";
        environmentFiles = [ host-config.sops.secrets.passbolt_mariadb.path ];
        environment = {
          MYSQL_DATABASE = "passbolt";
          MYSQL_USER = "passbolt";
        };
      };
    };
  };


  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 8080 ];
    };
    # Use systemd-resolved inside the container
    # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
    useHostResolvConf = lib.mkForce false;
  };

  services.resolved.enable = true;

  system.stateVersion = "23.11";
}
