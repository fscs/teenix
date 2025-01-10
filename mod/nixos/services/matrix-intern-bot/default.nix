{ lib
, config
, inputs
, pkgs
, ...
}:
{
  options.teenix.services.matrix-intern-bot = {
    enable = lib.mkEnableOption "setup matrix-intern-bot";
    secretsFile = lib.mkOption {
      type = lib.types.path;
      description = "path to the sops secret file for the matrix-intern-bot";
    };
    dbHostPath = lib.mkOption {
      type = lib.types.str;
    };
  };

  config =
    let
      opts = config.teenix.services.matrix-intern-bot;
    in
    lib.mkIf opts.enable {
      sops.secrets.matrix-intern-bot = {
        sopsFile = opts.secretsFile;
        format = "binary";
        mode = "444";
      };

      nix-tun.storage.persist.subvolumes."matrix-intern-bot".directories = {
        "/db" = {
          owner = "${builtins.toString config.containers.matrix-intern-bot.config.users.users.matrix-intern-bot.uid}";
          mode = "0700";
        };
      };

      containers.matrix-intern-bot = {
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.118.10";
        localAddress = "192.168.118.11";
        bindMounts = {
          "resolv" = {
            hostPath = "/etc/resolv.conf";
            mountPoint = "/etc/resolv.conf";
          };
          "secret" = {
            hostPath = config.sops.secrets.matrix-intern-bot.path;
            mountPoint = config.sops.secrets.matrix-intern-bot.path;
          };
          "home" = {
            hostPath = "${config.nix-tun.storage.persist.path}/matrix-intern-bot/db";
            mountPoint = "/home/matrix-intern-bot/";
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
