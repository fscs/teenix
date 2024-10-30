{ inputs
, outputs
, config
, pkgs
, lib
, ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../locale.nix

    inputs.sops.nixosModules.sops
    inputs.nix-tun.nixosModules.nix-tun

    outputs.nixosModules.teenix
  ];

  environment.systemPackages = [
    inputs.campus-guesser-server.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.git
    pkgs.kitty
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];

  networking = {
    nameservers = [ "134.99.154.201" "134.99.154.228" ];
    defaultGateway = {
      address = "134.99.154.1";
      interface = "ens32";
    };
  };

  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-+" ];
    externalInterface = "ens32";
    # Lazy IPv6 connectivity for the container
    enableIPv6 = true;
  };

  teenix.services.collabora = {
    enable = true;
    hostname = "collabora.inphima.de";
    nextcloudHost = "nextcloud.inphima.de";
  };

  teenix.services.traefik.redirects."essen_inphima" = {
    from = "essen.inphima.de";
    to = "www.stw-d.de/gastronomie/speiseplaene/essenausgabe-sued-duesseldorf";
  };

  teenix.services.traefik.redirects."wiki_inphima_de" = {
    from = "wiki.inphima.de";
    to = "wiki.hhu.de/display/INPHIMA/INPhiMa+Startseite";
  };

  teenix.services.traefik.redirects."physik_inphima" = {
    from = "physik.inphima.de";
    to = "fsphy.de";
  };

  teenix.services.traefik.redirects."status_inphima" = {
    from = "status.inphima.de";
    to = "grafana.hhu-fscs.de/public-dashboards/84a25d574e334559b2095f1d5c573be6";
  };

  teenix.services.traefik.redirects."inphima_discord" = {
    from = "fscs.hhu.de/discord";
    to = "discord.gg/K3ddgjh";
  };

  virtualisation.vmware.guest.enable = true;

  networking.interfaces.ens34 = {
    ipv4 = {
      addresses = [
        {
          address = "134.99.147.42";
          prefixLength = 27;
        }
      ];
      routes = [
        {
          address = "134.99.210.131";
          prefixLength = 32;
          via = "134.99.147.33";
        }
      ];
    };
  };

  networking.firewall =
    {
      allowedUDPPortRanges = [{ from = 30000; to = 30010; }];
    };

  networking.firewall.checkReversePath = false;

  sops.secrets.traefik = {
    format = "binary";
    mode = "444";
    sopsFile = ../secrets/traefik;
  };


  networking.firewall.logRefusedConnections = true;

  teenix.nixconfig.enable = true;
  teenix.nixconfig.allowUnfree = true;
  teenix.bootconfig.enable = true;

  teenix.services.openssh.enable = true;

  networking.hostName = "teefax";

  users.defaultUserShell = pkgs.fish;

  programs.fish.enable = true;

  teenix.services.traefik.enable = true;
  teenix.services.traefik.staticConfigPath = ../secrets/traefik_static;
  teenix.services.traefik.dashboardUrl = "traefik.hhu-fscs.de";
  teenix.services.traefik.letsencryptMail = "fscs@hhu.de";
  teenix.services.traefik.logging.enable = true;

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
  } //
  (builtins.foldl'
    lib.trivial.mergeAttrs
    { }
    (builtins.map (i: { "turn_port_udp_${builtins.toString i}" = { port = i; }; })
      (lib.range 30000 30010)));

  teenix.services.sliding-sync = {
    enable = true;
    hostname = "syncv3.inphima.de";
    envFile = ../secrets/sliding_env;
  };

  # Services
  nix-tun.storage.persist.enable = true;

  teenix.services.helfendentool = {
    enable = true;
    hostname = "helfendentool.inphima.de";
    secretsFile = ../secrets/helfendentool_yaml;
    rabbitmqSecret = ../secrets/helfendtool_rabbitmq;
  };

  teenix.services.nextcloud = {
    enable = true;
    hostname = "nextcloud.inphima.de";
    secretsFile = ../secrets/nextcloud;
    extraApps = [
    ];
  };

  teenix.services.keycloak = {
    enable = true;
    hostname = "login.inphima.de";
    secretsFile = ../secrets/keycloak;
  };

  teenix.services.fscshhude = {
    enable = true;
    hostname = "hhu-fscs.de";
    secretsFile = ../secrets/fscshhude;
  };

  teenix.services.matrix = {
    enable = true;
    servername = "inphima.de";
    secretsFile = ../secrets/test_pwd;
    configFile = ../secrets/matrix_config;
    masSecrets = ../secrets/masconfig_yaml;
  };

  teenix.services.element-web = {
    enable = true;
    hostname = "element.inphima.de";
    matrixUrl = "inphima.de";
  };

  teenix.services.pretix = {
    enable = true;
    hostname = "pretix.inphima.de";
    email = "fscs@hhu.de";
  };

  teenix.services.mete = {
    enable = true;
    hostname = "mete.hhu-fscs.de";
    hostname-summary = "gorden-summary.hhu-fscs.de";
  };

  teenix.services.authentik = {
    enable = true;
    hostname = "auth.inphima.de";
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

  teenix.services.discord-intern-bot = {
    enable = true;
    secretsFile = ../secrets/discordinternbot;
  };

  teenix.services.traefik.services.onlyoffice = config.nix-tun.services.traefik.services.onlyoffice;

  nix-tun.services.containers.onlyoffice = {
    enable = true;
    hostname = "office.inphima.de";
    jwtSecretFile = ../secrets/onlyoffice;
  };

  teenix.services.inphimade = {
    enable = true;
    hostname = "inphima.de";
    envFile = ../secrets/inphimade/env;
    mariaEnvFile = ../secrets/inphimade/maria_env;
  };

  teenix.services.nawi = {
    enable = true;
    hostname = "fsnawi.de";
    envFile = ../secrets/nawi/env;
    mariaEnvFile = ../secrets/nawi/maria_env;
  };

  teenix.services.sydent = {
    enable = true;
    hostname = "sydent.inphima.de";
  };

  teenix.services.campus-guesser-server = {
    enable = true;
    hostname = "campusguesser.inphima.de";
    secretsFile = ../secrets/campusguesser;
  };

  teenix.services.node_exporter = {
    enable = true;
  };

  teenix.services.gitlab-runner = {
    enable = true;
    secretsFile = ../secrets/gitlab_runner;
  };

  teenix.services.vaultwarden = {
    enable = true;
    secretsFile = ../secrets/vaultwarden;
    hostname = "vaultwarden.hhu-fscs.de";
  };

  teenix.services.ntfy = {
    enable = true;
    hostname = "ntfy.hhu-fscs.de";
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
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCtvtqwAan/ubiGOe01Vhda6fTlI8AP3PQQ4RsQ+GqPGjH5jVOT8WUm4a1Ed7kC26pesUgC/67wu2PhlqfhzagaPqDV+Yt/HaOSG7fB3PYLyewt66l1P/3X5gszZ5Z1NGcx0xj8sWB1Y88i9BKO3V3LbnEY/XXSgE4XxxMRlXJydt/5Hq8zodd8mXFJWWbNS+xoTM2fRcKn8Gq72qU+LTNDV8xmzLjMG/PxL/4lveKusvBMtK/V9eKkd/Mt9Wen/ICR0JlcNqxfkt+kVt+YXJhppLOiNDxVzdK88wACK1DMHxBSQjcSRC9/USicmal7hApxMB41BLqgbDmtT22Umyf1kSSicaN7+IfijoGuT084Tu5zc2YGFSAe9iRet1i4glXazrgdsk6I/3FQQc1c1eC8ni3j36/9V8FBIe7+GmL+czdR0zSnL1VMIEchps9YnVHNFOkrgMKOV84mm23Zrf7sXFme7I5oXRXXP50taqCfCUbK8uwT6S1FIZhvn23GFM3IllIH8wY7uLtpOB5TxPLmZJjgXXo8eRHqF1wnYbytU1V+MlTP6MaeWzZnOMhKEK5D9ouCTA9iYNi0cGbDJLldMcwYnd+2/kFd0p2iQcWUqebC1DnL44biNP0Hc9d8rF/jc88aotpTCVEosSTAn++b4aVdYP8TAGN5GxSWqKpnCQ== u0_a250@localhost"
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
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbxDGg250fa1tE9HK4U1G3Uee2L7p5kA+V82RAIL89b yesmachine"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIpq+pnhT8eedChvTk1uIWvKR2WXWRFcYPkzm4lR0XUk nix-on-droid"
      ];
    };

    gitlab = {
      shell = pkgs.bash;
      setSopsPassword = false;
      sshKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDiu4iPkKfORYXnpTBiU+MQGPZ8jQ3a8BXxfmXoD1irlB5ej0r/GM034YcoxBG18ZoK0kf8zsLhfP8GkLr65XZBaRD29IBs0nAjm8oGo+ZMoETFbJj2ChZx/+fCUqKzCDOp8RcackQlBQ+u01HDtbwMHvIwx6pew7Z6n52A9pjSh7khEUSDTzh/wRzbN3lhaGWSmA3HFgR1TNTZT3r4lKq3A6+49OXD34NReAHIoAu7gkfpreS5icdYBS+B92O/coaOXiqtQWlLbseBoTHBaw5o/5pAyxpIUm3L98xTnGHKLz+KQUDTN6fRvLE2OZ9eKbakfRWYpg2J9i75AXhWzXWBCsylFDnP64ZO6IkBHQ5JSdIwwQOYuhZbIo+1nTnzCL1YXiy39b9aySBf1b9kvItIrSr1hpqVQuVX4Z8t5U5z3molSR4ylyzaS++ZQAXMBjSroc9EU/zq5Jiywj0c4jqzYN6O1ejGv/yo7BPw2HNJS16saAkmZ7kWmqXBNKPXXbs= teefax"
      ];
    };
  };

  system.stateVersion = "23.11";
}
