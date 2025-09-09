{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.teenix.services.helfendentool;
  yaml = pkgs.formats.yaml { };

  secrets = [
    "helfendentool-rabbitmq-password"
    "helfendentool-database-password"
    "helfendentool-smtp-password"
    "helfendentool-oauth-client-id"
    "helfendentool-oauth-client-secret"
    "helfendentool-secret"
  ];
in
{
  options.teenix.services.helfendentool = {
    enable = lib.mkEnableOption "helfendentool";
    hostname = lib.teenix.mkHostnameOption "helfendentool";
    secretsFile = lib.teenix.mkSecretsFileOption "helfendentool";
    settings = lib.mkOption {
      type = yaml.type;
      description = "proxy option";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = lib.genAttrs secrets (name: {
      sopsFile = cfg.secretsFile;
      key = lib.removePrefix "helfendentool-" name;
      mode = "0444";
    });

    teenix.services.helfendentool.settings = {
      docker = true;

      files = {
        static = "static";
        media = "media";
        tmp = "/tmp";
      };

      language = {
        default = "de";
        badges = "de";
        timezone = "Europe/Berlin";
        country = "DE";
      };

      database = {
        backend = "postgresql";
        name = "helfertool";
        user = "helfertool";
        host = "postgressql";
        port = 5432;
        password = config.sops.placeholder.helfendentool-database-password;
      };

      rabbitmq = {
        vhost = "helfertool";
        user = "helfertool";
        host = "rabbitmq";
        port = 5672;
        password = config.sops.placeholder.helfendentool-rabbitmq-password;
      };

      mail = {
        send = {
          host = "mail.hhu.de";
          port = 465;
          user = "noreply-fscs";
          tls = true;
          starttls = false;
          password = config.sops.placeholder.helfendentool-smtp-password;
        };

        sender_address = "noreply-fscs@hhu.de";
        sender_name = "Helfertool";
        batch_size = 200;
        batch_gap = 5;
      };

      authentication = {
        local_user_char = "@";
        oidc = {
          provider_name = "PhyNIx";
          provider = {
            authorization_endpoint = "https://${config.teenix.services.authentik.hostname}/application/o/authorize/";
            token_endpoint = "https://${config.teenix.services.authentik.hostname}/application/o/token/";
            user_endpoint = "https://${config.teenix.services.authentik.hostname}/application/o/userinfo/";
            jwks_uri = "https://${config.teenix.services.authentik.hostname}/application/o/helfertool/jwks/";

            client_id = config.sops.placeholder.helfendentool-oauth-client-id;
            client_secret = config.sops.placeholder.helfendentool-oauth-client-secret;

            logout = {
              endpoint = "https://${config.teenix.services.authentik.hostname}/application/o/helfertool/end-session/";
              redirect_parameter = "redirect_uri";
            };

            claims = {
              login = {
                compare = "member";
                path = "groups";
                value = "FS_Rat_PhyNIx";
              };
              admin = {
                compare = "member";
                path = "groups";
                value = "FS_Rat_PhyNIx";
              };
            };

            thirdparty_domain = false;
            renew_check_interval = 15;
          };
        };
      };

      security = {
        debug = true;
        behind_proxy = true;
        password_length = 12;
        lockout = {
          limit = 5;
          time = 10;
        };
        secret = config.sops.placeholder.helfendentool-secret;
        allowed_hosts = [
          "helfer.phynix-hhu.de"
          "helfende.phynix-hhu.de"
          "helfendentool.phynix-hhu.de"
          "www.helfer.phynix-hhu.de"
          "www.helfende.phynix-hhu.de"
        ];
      };

      features = {
        newsletter = true;
        badges = true;
        gifts = true;
        prerequisites = true;
        inventory = true;
        corona = false;
      };

      customization = {
        display.events_last_years = 2;

        search.similarity = 0.3;

        contact_address = "fscs@hhu.de";

        urls = {
          imprint = "https://hhu-fscs.de/kontakt/impressum/";
          privacy = "https://static.hhu-fscs.de/datenschutz-helfertool/";
          docs = "https://docs.helfertool.org";
        };
      };

      badges = {
        pdflatex = "/usr/bin/pdflatex";
        template = "src/badges/latextemplate/badge.tex";
        photo_max_size = 1000;
        special_badges_max = 50;
        pdf_timeout = 30;
        rm_delay = 2;
      };

      newsletter = {
        subscribe_deadline = 3;
      };
    };

    sops.templates.helfendentool-config = {
      file = yaml.generate "helfendentool-config" cfg.settings;
      mode = "444";
      restartUnits = [
        "docker-helfendentool-helfertool.service"
        "docker-helfendentool-rabbitmq.service"
      ];
    };

    sops.templates.helfendentool-rabbitmq = {
      content = ''
        RABBITMQ_DEFAULT_PASS=${config.sops.placeholder.helfendentool-rabbitmq-password}
      '';
      
      restartUnits = [
        "docker-helfendentool-helfertool.service"
        "docker-helfendentool-rabbitmq.service"
      ];
    };

    teenix.persist.subvolumes.helfendentool.directories = {
      data = {
        mode = "0777";
      };
      config = {
        mode = "0777";
      };
      run = {
        mode = "0777";
      };
      log = {
        mode = "0777";
      };
      postgres = {
        mode = "0777";
      };
    };

    # Containers
    virtualisation.oci-containers.containers.helfendentool-helfertool = {
      image = "ghcr.io/fscs/helfertool:dockertest";
      volumes = [
        "${config.sops.templates.helfendentool-config.path}:/config/helfertool.yaml"
        "${config.teenix.persist.subvolumes.helfendentool.path}/data:/data"
        "${config.teenix.persist.subvolumes.helfendentool.path}/log:/log"
        "${config.teenix.persist.subvolumes.helfendentool.path}/run:/run"
      ];
      dependsOn = [
        "helfendentool-postgressql"
        "helfendentool-rabbitmq"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.helfertool.entrypoints" = "websecure";
        "traefik.http.routers.helfertool.rule" =
          "Host(`${config.teenix.services.helfendentool.hostname}`) || Host(`www.${config.teenix.services.helfendentool.hostname}`)";
        "traefik.http.routers.helfertool.tls" = "true";
        "traefik.http.routers.helfertool.tls.certresolver" = "letsencrypt";
        "traefik.http.services.helfertool.loadbalancer.server.port" = "8000";
        "traefik.http.routers.helfertool.middlewares" = "hsts@file";
      };
      log-driver = "journald";
      extraOptions = [
        "--network-alias=helfertool"
        "--network=helfendentool_default"
      ];
    };
    systemd.services.docker-helfendentool-helfertool = {
      serviceConfig = {
        Restart = lib.mkOverride 500 "always";
        RestartMaxDelaySec = lib.mkOverride 500 "1m";
        RestartSec = lib.mkOverride 500 "100ms";
        RestartSteps = lib.mkOverride 500 9;
      };
      after = [
        "docker-network-helfendentool_default.service"
      ];
      requires = [
        "docker-network-helfendentool_default.service"
      ];
      partOf = [
        "docker-compose-helfendentool-root.target"
      ];
      wantedBy = [
        "docker-compose-helfendentool-root.target"
      ];
    };
    virtualisation.oci-containers.containers.helfendentool-postgressql = {
      image = "postgres:14";
      environment = {
        "POSTGRES_DB" = "helfertool";
        "POSTGRES_USER" = "helfertool";
      };
      volumes = [
        "${config.teenix.persist.path}/helfendentool/postgres:/var/lib/postgresql/data"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=postgressql"
        "--network=helfendentool_default"
      ];
    };
    systemd.services.docker-helfendentool-postgressql = {
      serviceConfig = {
        Restart = lib.mkOverride 500 "always";
        RestartMaxDelaySec = lib.mkOverride 500 "1m";
        RestartSec = lib.mkOverride 500 "100ms";
        RestartSteps = lib.mkOverride 500 9;
      };
      after = [
        "docker-network-helfendentool_default.service"
      ];
      requires = [
        "docker-network-helfendentool_default.service"
      ];
      partOf = [
        "docker-compose-helfendentool-root.target"
      ];
      wantedBy = [
        "docker-compose-helfendentool-root.target"
      ];
    };
    virtualisation.oci-containers.containers.helfendentool-rabbitmq = {
      image = "rabbitmq";
      environment = {
        "RABBITMQ_DEFAULT_USER" = "helfertool";
        "RABBITMQ_DEFAULT_VHOST" = "helfertool";
      };
      environmentFiles = [
        "${config.sops.templates.helfendentool-rabbitmq.path}"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=rabbitmq"
        "--network=helfendentool_default"
      ];
    };
    systemd.services.docker-helfendentool-rabbitmq = {
      serviceConfig = {
        Restart = lib.mkOverride 500 "always";
        RestartMaxDelaySec = lib.mkOverride 500 "1m";
        RestartSec = lib.mkOverride 500 "100ms";
        RestartSteps = lib.mkOverride 500 9;
      };
      after = [
        "docker-network-helfendentool_default.service"
      ];
      requires = [
        "docker-network-helfendentool_default.service"
      ];
      partOf = [
        "docker-compose-helfendentool-root.target"
      ];
      wantedBy = [
        "docker-compose-helfendentool-root.target"
      ];
    };

    # Networks
    systemd.services.docker-network-helfendentool_default = {
      path = [ pkgs.docker ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "docker network rm -f helfendentool_default";
      };
      script = ''
        docker network inspect helfendentool_default || docker network create helfendentool_default
      '';
      partOf = [ "docker-compose-helfendentool-root.target" ];
      wantedBy = [ "docker-compose-helfendentool-root.target" ];
    };

    # Root service
    # When started, this will automatically create all resources and start
    # the containers. When stopped, this will teardown all resources.
    systemd.targets.docker-compose-helfendentool-root = {
      unitConfig = {
        Description = "Root target generated by compose2nix.";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
