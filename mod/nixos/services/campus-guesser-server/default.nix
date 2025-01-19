{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
{
  options.teenix.services.campus-guesser-server = {
    enable = lib.mkEnableOption "setup campus-guesser-server";
    hostname = lib.teenix.mkHostnameOption;
    secretsFile = lib.teenix.mkSecretsFileOption "campus-guesser-server";
  };

  config =
    let
      opts = config.teenix.services.campus-guesser-server;
    in
    lib.mkIf opts.enable {
      sops.secrets.campusguesser = {
        sopsFile = opts.secretsFile;
        format = "binary";
        mode = "444";
      };

      nix-tun.storage.persist.subvolumes."campus-guesser-server".directories = {
        "/data" = {
          owner = "${builtins.toString config.containers.campus-guesser-server.config.users.users.campus-guesser-server.uid}";
          mode = "0700";
        };
      };

      teenix.services.traefik.services."campus_guessser" = {
        router = {
          rule = "Host(`${opts.hostname}`)";
        };
        servers = [ "http://${config.containers.campus-guesser-server.config.networking.hostName}:8080" ];
        healthCheck.enable = true;
      };

      containers.campus-guesser-server = {
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.114.10";
        localAddress = "192.168.114.11";
        bindMounts = {
          "db" = {
            hostPath = "${config.nix-tun.storage.persist.path}/campus-guesser-server/postgres";
            mountPoint = "/var/lib/postgresql";
            isReadOnly = false;
          };
          "images" = {
            hostPath = "${config.nix-tun.storage.persist.path}/campus-guesser-server/data";
            mountPoint = "/var/lib/campus-guesser/images";
            isReadOnly = false;
          };
          "secret" = {
            hostPath = config.sops.secrets.campusguesser.path;
            mountPoint = config.sops.secrets.campusguesser.path;
          };
          "resolv" = {
            hostPath = "/etc/resolv.conf";
            mountPoint = "/etc/resolv.conf";
          };
          "logs" = {
            hostPath = "/var/log/campusguesser";
            mountPoint = "/var/log/campusguesser";
            isReadOnly = false;
          };
        };

        specialArgs = {
          inherit inputs;
          host-config = config;
        };

        config = import ./container.nix;
      };
    };
}
