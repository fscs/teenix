{ lib
, config
, inputs
, ...
}: {
  options.teenix.services.passbolt = {
    enable = lib.mkEnableOption "setup passbolt";
    hostname = lib.mkOption {
      type = lib.types.str;
      description = "hostname";
    };
  };
  config =
    let
      opts = config.teenix.services.passbolt;
    in
    lib.mkIf opts.enable {
      teenix.services.traefik.services."passbolt" = {
        router.rule = "Host(`${opts.hostname}`)";
        servers = [ "http://${config.containers.passbolt.config.networking.hostName}" ];
      };

      containers.passbolt = {
        ephemeral = true;
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.109.10";
        localAddress = "192.168.109.11";

        bindMounts =
          {
            "db" = {
              hostPath = "${config.nix-tun.storage.persist.path}/passbolt/postgres";
              mountPoint = "/var/lib/postgres";
              isReadOnly = false;
            };
          };

        config = { pkgs, lib, ... }: {

          system.stateVersion = "23.11";

          networking = {
            firewall = {
              enable = true;
              allowedTCPPorts = [ 80 ];
            };
            # Use systemd-resolved inside the container
            # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
            useHostResolvConf = lib.mkForce false;
          };

          services.resolved.enable = true;
        };
      };
    };
}
