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
  };

  config =
    let
      opts = config.teenix.services.campus-guesser-server;
    in
    lib.mkIf opts.enable {
      nix-tun.storage.persist.subvolumes."campus-guesser-server" = { };

      teenix.services.traefik.services."campus_guessser" = {
        router =
          {
            rule = "Host(`${opts.hostname}`)";
            middlewares = [ "authentik" ];
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
        };

        specialArgs = {
          inherit inputs pkgs;
          host-config = config;
        };

        config = import ./container.nix;
      };
    };
}
