{ lib
, config
, inputs
, pkgs
, ...
}: {
  options.teenix.services.matrix = {
    enable = lib.mkEnableOption "setup inphimatrix";
    servername = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Servername for matrix. The Matrix Host will be matrix.servername, except for .well-known files";
    };
    secretsFile = lib.mkOption {
      type = lib.types.path;
    };
    configFile = lib.mkOption {
      type = lib.types.path;
    };
  };

  config =
    let
      opts = config.teenix.services.matrix;
    in
    lib.mkIf opts.enable {
      sops.secrets.matrix_pass = {
        sopsFile = opts.secretsFile;
        format = "binary";
        mode = "444";
      };

      sops.secrets.matrix_env = {
        sopsFile = opts.configFile;
        format = "binary";
        mode = "444";
      };

      nix-tun.storage.persist.subvolumes."inphimatrix".directories = {
        "/postgres" = {
          owner = "${builtins.toString config.containers.inphimatrix.config.users.users.postgres.uid}";
          mode = "0700";
        };
      };

      teenix.services.traefik.services.inphimatrix = {
        router.rule = "Host(`matrix.${opts.servername}`) || (Host(`${opts.servername}`) && (Path(`/_matrix/{name:.*}`) || Path(`/_synapse/{name:.*}`) || Path(`/.well-known/matrix/server`) || Path(`/.well-known/matrix/client`)))";
        servers = [ "http://${config.containers.inphimatrix.config.networking.hostName}:8008" ];
        healthCheck = true;
      };

      containers.inphimatrix = {
        ephemeral = true;
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.105.10";
        localAddress = "192.168.105.11";
        bindMounts = {
          "secret" = {
            hostPath = config.sops.secrets.matrix_pass.path;
            mountPoint = config.sops.secrets.matrix_pass.path;
          };
          "env" = {
            hostPath = config.sops.secrets.matrix_env.path;
            mountPoint = config.sops.secrets.matrix_env.path;
          };
          "db" = {
            hostPath = "${config.nix-tun.storage.persist.path}/inphimatrix/postgres";
            mountPoint = "/var/lib/postgres";
            isReadOnly = false;
          };
        };

        config =
          { lib
          , ...
          }: {
            # enable postgres
            services.postgresql = {
              enable = true;
              ensureDatabases = [
                "matrix-synapse"
              ];
              initdbArgs = [
                "--locale=C --encoding utf8"
              ];
              ensureUsers = [
                {
                  name = "matrix-synapse";
                  ensureDBOwnership = true;
                }
              ];
              dataDir = "/var/lib/postgres";
              authentication = pkgs.lib.mkOverride 10 ''
                #type database  DBuser  auth-method
                local all       all     trust
              '';
            };
            # enable synapse
            services.matrix-synapse = {
              enable = true;
              extraConfigFiles = [ config.sops.secrets.matrix_env.path ];
              settings = with config.containers.inphimatrix.config.services.coturn; {
                enable_registration = true;
                enable_registration_without_verification = true;
                turn_uris = [ "turn:${realm}:3478?transport=udp" "turn:${realm}:3478?transport=tcp" ];
                turn_shared_secret = static-auth-secret-file;
                turn_user_lifetime = "1h";
                server_name = "matrix.${opts.servername}";
                oidc_providers = "";

                listeners = [
                  {
                    port = 8008;
                    bind_addresses = [ "0.0.0.0" ];
                    type = "http";
                    tls = false;
                    x_forwarded = true;
                    resources = [
                      {
                        names = [ "client" "federation" ];
                        compress = true;
                      }
                    ];
                  }
                ];
              };
            };

            # enable coturn
            services.coturn = {
              enable = true;
              no-cli = true;
              no-tcp-relay = true;
              min-port = 49000;
              max-port = 50000;
              use-auth-secret = true;
              static-auth-secret-file = "/run/secrets/matrix_pass";
              extraConfig = ''
                # for debugging
                verbose
                # ban private IP ranges
                no-multicast-peers
                denied-peer-ip=0.0.0.0-0.255.255.255
                denied-peer-ip=10.0.0.0-10.255.255.255
                denied-peer-ip=100.64.0.0-100.127.255.255
                denied-peer-ip=127.0.0.0-127.255.255.255
                denied-peer-ip=169.254.0.0-169.254.255.255
                denied-peer-ip=172.16.0.0-172.31.255.255
                denied-peer-ip=192.0.0.0-192.0.0.255
                denied-peer-ip=192.0.2.0-192.0.2.255
                denied-peer-ip=192.88.99.0-192.88.99.255
                denied-peer-ip=192.168.0.0-192.168.255.255
                denied-peer-ip=198.18.0.0-198.19.255.255
                denied-peer-ip=198.51.100.0-198.51.100.255
                denied-peer-ip=203.0.113.0-203.0.113.255
                denied-peer-ip=240.0.0.0-255.255.255.255
                denied-peer-ip=::1
                denied-peer-ip=64:ff9b::-64:ff9b::ffff:ffff
                denied-peer-ip=::ffff:0.0.0.0-::ffff:255.255.255.255
                denied-peer-ip=100::-100::ffff:ffff:ffff:ffff
                denied-peer-ip=2001::-2001:1ff:ffff:ffff:ffff:ffff:ffff:ffff
                denied-peer-ip=2002::-2002:ffff:ffff:ffff:ffff:ffff:ffff:ffff
                denied-peer-ip=fc00::-fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
                denied-peer-ip=fe80::-febf:ffff:ffff:ffff:ffff:ffff:ffff:ffff
              '';
            };

            networking.nameservers = [ "9.9.9.9" ];
            # open the firewall
            networking.firewall =
              let
                range = with config.services.coturn;
                  lib.singleton
                    {
                      from = min-port;
                      to = max-port;
                    };
              in
              {
                allowedUDPPortRanges = range;
                allowedUDPPorts = [ 3478 5349 ];
                allowedTCPPortRanges = [ ];
                allowedTCPPorts = [ 80 443 8008 3478 5349 ];
              };

            system.stateVersion = "23.11";
          };
      };
    };
}
