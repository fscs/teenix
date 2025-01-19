{
  lib,
  config,
  pkgs,
  pkgs-master,
  inputs,
  ...
}:
{
  options.teenix.services.nextcloud = {
    enable = lib.mkEnableOption "setup nextcloud";
    hostname = lib.teenix.mkHostnameOption;
    secretsFile = lib.teenix.mkSecretsFileOption "nextcloud";
    extraApps = lib.mkOption {
      description = "nextcloud apps to install";
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config =
    let
      opts = config.teenix.services.nextcloud;
    in
    lib.mkIf opts.enable {
      sops.secrets.nextcloud_pass = {
        sopsFile = opts.secretsFile;
        format = "binary";
        mode = "444";
      };

      nix-tun.utils.containers.nextcloud.volumes = {
        "/var/lib/mysql" = {
          owner = "mysql";
          mode = "0700";
        };
        "/var/lib/nextcloud" = {
          owner = "nextcloud";
          mode = "0700";
        };
      };

      nix-tun.storage.persist.subvolumes."scanner" = {
        owner = "${builtins.toString config.containers.nextcloud.config.users.users.nextcloud.uid}";
        mode = "0777";
      };
      teenix.services.traefik.services."nextcloud" = {
        router.rule = "Host(`${opts.hostname}`)";
        servers = [ "http://${config.containers.nextcloud.config.networking.hostName}" ];
        healthCheck = {
          enable = true;
          path = "/login";
        };
      };

      services.traefik.staticConfigOptions.entryPoints.websecure.proxyProtocol.insecure = true;

      teenix.services.traefik.redirects."cloud_inphima" = {
        from = "cloud.inphima.de";
        to = "nextcloud.inphima.de";
      };
      teenix.services.traefik.redirects."klausur_inphima" = {
        from = "klausur.inphima.de";
        to = "nextcloud.inphima.de/s/K6xSKSXmJRQAiia";
      };
      # teenix.services.traefik.redirects."klausur_inphima2" = {
      #   from = "https://www.inphima.de/klausurarchiv/";
      #   to = "nextcloud.inphima.de/s/K6xSKSXmJRQAiia";
      # };

      containers.nextcloud = {
        autoStart = true;
        ephemeral = true;
        privateNetwork = true;
        timeoutStartSec = "5min";
        hostAddress = "192.168.100.10";
        localAddress = "192.168.100.11";
        bindMounts = {
          "docker" = {
            hostPath = "/var/run/docker.sock";
            mountPoint = "/var/run/docker.sock";
            isReadOnly = false;
          };
          "resolv" = {
            hostPath = "/etc/resolv.conf";
            mountPoint = "/etc/resolv.conf";
          };
          "secret" = {
            hostPath = config.sops.secrets.nextcloud_pass.path;
            mountPoint = config.sops.secrets.nextcloud_pass.path;
          };
          "data" = {
            hostPath = "/mnt/netapp/Nextcloud";
            mountPoint = "/var/lib/nextcloud/data";
            isReadOnly = false;
          };
          "scanner" = {
            hostPath = "/persist/scanner";
            mountPoint = "/var/lib/scanner";
            isReadOnly = false;
          };
        };

        specialArgs = {
          inherit inputs pkgs-master;
          host-config = config;
        };

        config = import ./container.nix;
      };
    };
}
