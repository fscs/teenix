{ lib
, config
, inputs
, pkgs
, ...
}: {
  options.teenix.services.fscshhude = {
    enable = lib.mkEnableOption "setup fscshhude";
    secretsFile = lib.mkOption {
      type = lib.types.path;
      description = "path to the sops secret file for the fscshhude website Server";
    };
    hostname = lib.mkOption {
      type = lib.types.str;
      description = "hostname";
    };
    db_hostPath = lib.mkOption {
      type = lib.types.str;
    };
  };
  config =
    let
      opts = config.teenix.services.fscshhude;
    in
    lib.mkIf opts.enable {
      sops.secrets.fscshhude = {
        sopsFile = opts.secretsFile;
        format = "binary";
        mode = "444";
      };

      teenix.services.traefik.services."fscshhude" = {
        router.rule = "Host(`${opts.hostname}`)";
        servers = [ "http://${config.containers.fscshhude.config.networking.hostName}:8080" ];
      };

      containers.fscshhude = {
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.103.10";
        localAddress = "192.168.103.11";
        bindMounts =
          {
            "secret" =
              {
                hostPath = config.sops.secrets.fscshhude.path;
                mountPoint = config.sops.secrets.fscshhude.path;
              };
            "db" = {
              hostPath = opts.db_hostPath;
              mountPoint = "/home/fscs-hhu/db";
              isReadOnly = false;
            };
          };

        config = { lib, ... }: {
          networking.hostName = "fscshhude";
          users.users.fscs-hhu = {
            home = "/home/fscs-hhu";
            group = "users";
            isNormalUser = true;
          };
          environment.systemPackages = [
            inputs.fscshhude.packages."${pkgs.stdenv.hostPlatform.system}".serve
            pkgs.bash
          ];
          systemd.services.fscs-website-serve = {
            description = "Serve FSCS website";
            after = [ "network.target" ];
            path = [ pkgs.bash ];
            serviceConfig = {
              EnvironmentFile = config.sops.secrets.fscshhude.path;
              Type = "exec";
              User = "fscs-hhu";
              WorkingDirectory = "/home/fscs-hhu";
              ExecStart = "${inputs.fscshhude.packages."${pkgs.stdenv.hostPlatform.system}".serve}/bin/serve";
              Restart = "always";
              RestartSec = 5;
            };
            wantedBy = [ "multi-user.target" ];
          };
          system.stateVersion = "23.11";

          networking = {
            firewall = {
              enable = true;
              allowedTCPPorts = [ 8080 ];
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
