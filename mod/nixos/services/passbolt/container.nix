{ lib
, host-config
, inputs
, ...
}:
let
  opts = host-config.teenix.services.passbolt;
in
{
  imports = [
    inputs.arion.nixosModules.arion
  ];
  virtualisation.arion = {
    backend = "docker";
    projects = {
      "passbolt".settings.services."passbolt".service = {
        image = "passbolt/passbolt";
        restart = "unless-stopped";
        env_file = [ host-config.sops.secrets.passbolt.path ];
        environment = {
          DATASOURCES_DEFAULT_HOST = "mariadb";
          DATASOURCES_DEFAULT_USERNAME = "passbolt";
          DATASOURCES_DEFAULT_DATABASE = "passbolt";
          DATASOURCES_DEFAULT_PORT = 3306;
          DATASOURCES_QUOTE_IDENTIFIER = true;
          APP_FULL_BASE_URL = "https://passbolt.fscs-hhu.de";
          EMAIL_DEFAULT_FROM = "fscs@hhu.de";
          EMAIL_TRANSPORT_DEFAULT_TLS = true;
          PASSBOLT_KEY_EMAIL = "fscs@hhu.de";
        };
      };
      "mariadb".settings.services."mariadb".service = {
        image = "mariadb";
        restart = "unless-stopped";
        env_file = [ host-config.sops.secrets.passbolt_mariadb.path ];
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
      allowedTCPPorts = [ 80 ];
    };
    # Use systemd-resolved inside the container
    # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
    useHostResolvConf = lib.mkForce false;
  };

  services.resolved.enable = true;

  system.stateVersion = "23.11";
}
