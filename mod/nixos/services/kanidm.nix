{ lib
, config
, inputs
, ...
}: {
  options.teenix.services.kanidm = {
    enable = lib.mkEnableOption "setup kanidm";
    hostname = lib.mkOption {
      type = lib.types.str;
      description = "hostname";
    };
    chainFile = lib.mkOption {
      type = lib.types.path;
      description = "path to the sops secret file for the fscshhude website Server";
    };
    keyFile = lib.mkOption {
      type = lib.types.path;
      description = "path to the sops secret file for the fscshhude website Server";
    };
  };
  config =
    let
      opts = config.teenix.services.kanidm;
    in
    lib.mkIf opts.enable {
      nix-tun.storage.persist.subvolumes."kanidm".directories = {
        "/postgres" = {
          owner = "${builtins.toString config.containers.kanidm.config.users.users.kanidm.uid}";
          mode = "0700";
        };
      };

      teenix.services.traefik.services."kanidm" = {
        router.rule = "Host(`${opts.hostname}`)";
        servers = [ "https://${config.containers.kanidm.config.networking.hostName}:8443" ];
      };

      containers.kanidm = {
        ephemeral = true;
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.112.10";
        localAddress = "192.168.112.11";

        bindMounts =
          {
            "key" =
              {
                hostPath = "${opts.keyFile}";
                mountPoint = "/run/key";
              };
            "chain" =
              {
                hostPath = "${opts.chainFile}";
                mountPoint = "/run/chain";
              };
            "db" = {
              hostPath = "${config.nix-tun.storage.persist.path}/kanidm";
              mountPoint = "/var/lib/kanidm";
              isReadOnly = false;
            };
          };

        config = { pkgs, lib, ... }: {

          networking.hostName = "kanidm";

          services.kanidm = {
            enableServer = true;
            serverSettings = {
              tls_chain = "/run/chain";
              tls_key = "/run/key";
              bindaddress = "[::]:8443";
              domain = "kanidm";
              origin = "https://kanidm:8443";
            };
          };

          system.stateVersion = "23.11";

          networking = {
            firewall = {
              enable = true;
              allowedTCPPorts = [ 8443 ];
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


