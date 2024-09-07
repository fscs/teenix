{ inputs
, outputs
, config
, pkgs
, ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../locale.nix

    inputs.sops.nixosModules.sops
    inputs.nix-tun.nixosModules.nix-tun

    outputs.nixosModules.teenix
  ];

  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-+" ];
    externalInterface = "enp1s0";
    # Lazy IPv6 connectivity for the container
    enableIPv6 = true;
  };

  teenix.nixconfig.enable = true;
  teenix.bootconfig.enable = true;

  teenix.services.openssh.enable = true;

  networking.hostName = "teefax";

  users.defaultUserShell = pkgs.fish;

  programs.fish.enable = true;

  teenix.services.traefik.enable = true;
  teenix.services.traefik.dashboardUrl = "traefik.hhu-fscs.de";
  teenix.services.traefik.letsencryptMail = "fscs@hhu.de";
  teenix.services.traefik.entrypoints = {
    web = {
      port = 80;
      http = {
        redirections = {
          entryPoint = {
            to = "websecure";
            scheme = "https";
          };
        };
      };
    };
    websecure = {
      port = 443;
    };
    ping = {
      port = 8082;
    };
    metrics = {
      port = 120;
    };
  };

  # Services
  nix-tun.storage.persist.enable = true;

  teenix.services.nextcloud = {
    enable = true;
    hostname = "cloud.hhu-fscs.de";
    secretsFile = ../secrets/test_pwd;
    extraApps = [
      "calendar"
      "deck"
      "polls"
      "forms"
      "tasks"
      "spreed"
    ];
  };

  teenix.services.keycloak = {
    enable = true;
    hostname = "login.hhu-fscs.de";
    secretsFile = ../secrets/test_pwd;
  };

  teenix.services.fscshhude = {
    enable = true;
    hostname = "hhu-fscs.de";
    secretsFile = ../secrets/fscshhude;
  };

  teenix.services.matrix = {
    enable = true;
    servername = "hhu-fscs.de";
    secretsFile = ../secrets/test_pwd;
    configFile = ../secrets/matrix_config;
  };

  teenix.services.element-web = {
    enable = true;
    hostname = "element.hhu-fscs.de";
    matrixUrl = "matrix.hhu-fscs.de";
  };

  teenix.services.pretix = {
    enable = true;
    hostname = "pretix.hhu-fscs.de";
    email = "fscs@hhu.de";
  };

  teenix.services.authentik = {
    enable = true;
    hostname = "auth.hhu-fscs.de";
    envFile = ../secrets/authentik_env;
  };

  teenix.services.prometheus = {
    enable = true;
    hostname = "prometheus.hhu-fscs.de";
    grafanaHostname = "grafana.hhu-fscs.de";
    alertmanagerURL = "alerts.hhu-fscs.de";
    envFile = ../secrets/prometheus_env;
  };

  teenix.services.passbolt = {
    enable = true;
    hostname = "passbolt.hhu-fscs.de";
    envFile = ../secrets/passbolt/env;
    mariaEnvFile = ../secrets/passbolt/maria_env;
  };

  teenix.services.fscs-intern-bot =
    {
      enable = true;
      secretsFile = ../secrets/fscsinternbot;
    };


  # teenix.services.inphimade = {
  #   enable = true;
  #   hostname = "inphima.hhu-fscs.de";
  #   envFile = ../secrets/inphimade/env;
  #   mariaEnvFile = ../secrets/inphimade/maria_env;
  # };

  # Users
  sops.secrets.felix_pwd = {
    format = "binary";
    sopsFile = ../secrets/test_pwd;
    neededForUsers = true;
  };

  security.pam.sshAgentAuth.enable = true;

  teenix.users = {
    teefax = {
      shell = pkgs.fish;
      setSopsPassword = false;
    };

    felix = {
      shell = pkgs.fish;
      setSopsPassword = false;
      sshKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCSzPwzWF8ETrEKZVrcldR5srYZB0debImh6qilNlH4va8jwVT835j4kTnwgDr/ODd5v0LagYiUVQqdC8gX/jQA9Ug9ju/NuPusyqro2g4w3r72zWFhIYlPWlJyxaP2sfUzUhnO0H2zFt/sEe8q7T+eDdHfKP+SIdeb9v9/oCAz0ZVUxCgkkK20hzhVHTXXMefjHq/zm69ygW+YpvWmvZ7liIDAaHL1/BzOtuMa3C8B5vP3FV5bh7MCSXyj5mIvPk7TG4e673fwaBYEB+2+B6traafSaSYlhHEm9H2CiRfEUa2NrBRHRv1fP4gM60350tUHLEJ8hM58LBymr3NfwxC00yODGfdaaWGxW4sxtlHw57Ev6uNvP2cN551NmdlRX7qKQKquyE4kUWHPDjJMKB8swj3F4/X6iAlGZIOW3ivcf+9fE+FUFA45MsbrijSWWnm/pOe2coP1KMvFNa6HMzCMImCAQPKpH5+LfT7eqfenDxgsJR5zm3LbrMJD6QhnBqPJsjH6gDzE17D5qctyMFy0DOad9+aVUWry1ymywSsjHuhMBcgQOgk3ZNdHIXQn5y6ejWaOJnWxZHFPKEeiwQK8LuE3cAj18p8r/rBnwhn7KHzlAgY0pgEZKrDSKIXDutFF9Y49hHyGpe3oI+oscBmH2xr0au/eNKlr/J85b9FdaQ=="
      ];
    };

    florian = {
      shell = pkgs.fish;
      setSopsPassword = false;
      sshKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCqlr0nKMcn6rZE0hn8RyzfgT75IxKwzgPn59WH1TSdskJNwRJh5UEDKtHA3eSxguWVdJqSDtbDeO7D6pofqPxMarhCoQwa79056e2LtDYVrABTQPabRSTreHDbMekj6RsxdHAg2BFayutEVwHHRKBuyK3DQd5hu4P3DM9t3c5Zd4XEUY4wB0N2EYy56/kw7uUM49dCX10GLSFVivVyUmb3IpFLmOt7s5I64JpsU5NGG4VdrsRJlG2U2q8f3PWf8tIhqONtR+wa7AYOKKGmBBuq7I1qX3lE7+sgxUc9CFfHVC8+OLclnCizlJaiqXIN+K35URyrqxY5Wf7POeSfhewB florian@yubikey"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDF5vhkEdRPrHHLgCMxm0oSrHU+uPM9W45Kdd/BKGreRp5vAA70vG3xEjzGdzIlhF0/qOZisA3MpjnMhW3l+uogTzuD3vDZdgT/pgoZEy2CIGIp9kbK5pQHhEhMbWi5NS5o8F095ZZRjBwRE1le9GmBZbYj3VUHSVaRxv+gZpSdqKBo9Arvr4L/lyTdpYgGEHUParWX+UtkBXSd0mO91h6XM8hEqLJv+ufbgA4az0O8sNTz2Uh+k3kN2sQn11O3ekGk4M9fpDP9+C17C9fbMpMATbFazl5pWnPqgLPrvNCs8dkKEJCRPgTgXHYaOppZ7hprJvMpOYW/IYyYo/1T2j6ELZJ7apMJNlOhWqVDnM5DGSIf65oNGZLiAupq1X+s6IoSEZOcAuWfTlJgRySdNgh/BSiKvmKG0nK8/z2ERN0/shE9/FT7pMyEfxHzNdl4PMvpPKZkucX1z4Pb3DtR684WRxD94lj5Nqh/3CH0EeLMJPwyFsOBNdsitqZGLHpGbOLZ3VDdjbOl2Qjgyl/VwzhAWNYUpyxZj3ZpFlHyDE0y38idXG7L0679THKzE62ZAnPdHHTP5RdWtRUqpPyO/nVXErOr8j55oO27C6jD0n5L4tU3QgSpjMOvomk9hbPzKEEuDGG++gSj9JoVHyAMtkWiYuamxR1UY1PlYBskC/q77Q== openpgp:0xB802445D"
      ];
    };

    tischgoblin = {
      shell = pkgs.fish;
      setSopsPassword = false;
      sshKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICAoWrXcbe0HbxOHRqbeSofUoYez8l5ydvTfpop0I5gD notuser@nixos"
      ];
    };
  };

  system.stateVersion = "23.11";
}
