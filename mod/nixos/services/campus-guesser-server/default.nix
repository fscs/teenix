{ lib
, config
, inputs
, pkgs
, ...
}: {
  options.teenix.services.campus-guesser-server = {
    enable = lib.mkEnableOption "setup campus-guesser-server";
    hostname = lib.mkOption {
      type = lib.types.str;
    };
    secretsFile = lib.mkOption {
      type = lib.types.path;
      description = "path to the sops secret file for the campusguesser Server";
    };
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

      nix-tun.storage.persist.subvolumes."campus-guesser-server" = { };

      teenix.services.traefik.services."campus_guessser" = {
        router =
          {
            rule = "Host(`${opts.hostname}`)";
          };
        servers = [ "http://${config.containers.campus-guesser-server.config.networking.hostName}:8080" ];
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
          "secret" = {
            hostPath = config.sops.secrets.campusguesser.path;
            mountPoint = config.sops.secrets.campusguesser.path;
          };
          "resolv" = {
            hostPath = "/etc/resolv.conf";
            mountPoint = "/etc/resolv.conf";
          };
        };

        specialArgs = {
          inherit inputs pkgs;
          host-config = config;
        };

        config = import ./container.nix;
      };
    };
}
