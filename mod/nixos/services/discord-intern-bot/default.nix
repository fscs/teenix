{ lib
, config
, inputs
, pkgs
, ...
}:
{
  options.teenix.services.discord-intern-bot = {
    enable = lib.mkEnableOption "setup discord-intern-bot";
    secretsFile = lib.mkOption {
      type = lib.types.path;
      description = "path to the sops secret file for the discord-intern-bot";
    };
    dbHostPath = lib.mkOption {
      type = lib.types.str;
    };
  };

  config =
    let
      opts = config.teenix.services.discord-intern-bot;
    in
    lib.mkIf opts.enable {
      sops.secrets.discord-intern-bot = {
        sopsFile = opts.secretsFile;
        format = "binary";
        mode = "444";
      };

      nix-tun.storage.persist.subvolumes."discord-intern-bot".directories = {
        "/db" = {
          owner = "${builtins.toString config.containers.discord-intern-bot.config.users.users.discord-intern-bot.uid}";
          mode = "0700";
        };
      };

      containers.discord-intern-bot = {
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.113.10";
        localAddress = "192.168.113.11";
        bindMounts = {
          "resolv" = {
            hostPath = "/etc/resolv.conf";
            mountPoint = "/etc/resolv.conf";
          };
          "secret" = {
            hostPath = config.sops.secrets.discord-intern-bot.path;
            mountPoint = config.sops.secrets.discord-intern-bot.path;
          };
          "home" = {
            hostPath = "${config.nix-tun.storage.persist.path}/discord-intern-bot/db";
            mountPoint = "/home/discord-intern-bot/";
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
