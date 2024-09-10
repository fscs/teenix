# Auto-generated using compose2nix v0.2.3-pre.
{ pkgs, lib, config, ... }:

{
  options.teenix.services.helfendentool = {
    enable = lib.mkEnableOption "Enable helfendentool";
    hostname = lib.mkOption {
      type = lib.types.str;
    };
    rabbitmqSecret = lib.mkOption {
      type = lib.types.path;
    };
    secretsFile = lib.mkOption {
      type = lib.types.path;
    };
  };

  config = lib.mkIf config.teenix.services.helfendentool.enable {
    sops.secrets.helfendentool = {
      sopsFile = config.teenix.services.helfendentool.secretsFile;
      format = "binary";
      mode = "444";
    };
    sops.secrets.helfendentool-rabbitmq = {
      sopsFile = config.teenix.services.helfendentool.rabbitmqSecret;
      format = "binary";
      mode = "444";
    };

    teenix.services.traefik.services."helfendentool" = {
      router.rule = "Host(`${config.teenix.services.helfendentool.hostname}`)";
      #TODO: Set the adderees dynamically maybe traefix docker impl
      servers = [ "http://172.21.0.4:8000" ];
    };

    teenix.services.traefik.redirects."helfer_redirect" = {
      from = "helfer.inphima.de";
      to = "helfendentool.inphima.de";
    };

    teenix.services.traefik.redirects."helfen_redirect" = {
      from = "helfen.inphima.de";
      to = "helfendentool.inphima.de";
    };

    teenix.services.traefik.redirects."helfende_redirect" = {
      from = "helfende.inphima.de";
      to = "helfendentool.inphima.de";
    };

    nix-tun.storage.persist.subvolumes."helfendentool".directories = {
      "data" = {
        mode = "0777";
      };
      "config" = {
        mode = "0777";
      };
      "run" = {
        mode = "0777";
      };
      "log" = {
        mode = "0777";
      };
      "postgres" = {
        mode = "0777";
      };
    };

    # Containers
    virtualisation.oci-containers.containers."helfendentool-helfertool" = {
      image = "ghcr.io/fscs/helfertool:dockertest";
      volumes = [
        "${config.sops.secrets.helfendentool.path}:/config/helfertool.yaml"
        "${config.nix-tun.storage.persist.path}/helfendentool/data:/data"
        "${config.nix-tun.storage.persist.path}/helfendentool/log:/log"
        "${config.nix-tun.storage.persist.path}/helfendentool/run:/run"
      ];
      dependsOn = [
        "helfendentool-postgressql"
        "helfendentool-rabbitmq"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=helfertool"
        "--network=helfendentool_default"
      ];
    };
    systemd.services."docker-helfendentool-helfertool" = {
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
    virtualisation.oci-containers.containers."helfendentool-postgressql" = {
      image = "postgres:14";
      environment = {
        "POSTGRES_DB" = "helfertool";
        "POSTGRES_USER" = "helfertool";
      };
      volumes = [
        "${config.nix-tun.storage.persist.path}/helfendentool/postgres:/var/lib/postgresql/data"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=postgressql"
        "--network=helfendentool_default"
      ];
    };
    systemd.services."docker-helfendentool-postgressql" = {
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
    virtualisation.oci-containers.containers."helfendentool-rabbitmq" = {
      image = "rabbitmq";
      environment = {
        "RABBITMQ_DEFAULT_USER" = "helfertool";
        "RABBITMQ_DEFAULT_VHOST" = "helfertool";
      };
      environmentFiles = [
        "${config.sops.secrets.helfendentool-rabbitmq.path}"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=rabbitmq"
        "--network=helfendentool_default"
      ];
    };
    systemd.services."docker-helfendentool-rabbitmq" = {
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
    systemd.services."docker-network-helfendentool_default" = {
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
    systemd.targets."docker-compose-helfendentool-root" = {
      unitConfig = {
        Description = "Root target generated by compose2nix.";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
