{ lib
, config
, inputs
, pkgs
, ...
}: {
  options.teenix.services.matrix = {
    enable = lib.mkEnableOption "setup inphimatrix";
    secretsFile = lib.mkOption {
      type = lib.types.path;
      description = "path to the sops secret file for the fscshhude website Server";
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

      containers.inphimatrix = {
        ephemeral = true;
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.105.10";
        localAddress = "192.168.105.11";
        bindMounts =
          {
            "secret" =
              {
                hostPath = config.sops.secrets.matrix_pass.path;
                mountPoint = config.sops.secrets.matrix_pass.path;
              };
            "db" = {
              hostPath = "/home/felix/db";
              mountPoint = "/var/lib/postgres";
              isReadOnly = false;
            };
          };

        config = { config, lib, ... }: {
          # enable postgres
          services.postgresql = {
            enable = true;
            ensureUsers = [
              {
                name = "matrix-synapse";
              }
            ];
            initialScript = pkgs.writeText "init-sql-script" ''
              CREATE DATABASE "matrix-synapse" ENCODING 'UTF8' LC_COLLATE='C' LC_CTYPE='C' template=template0;
              ALTER DATABASE "matrix-synapse" OWNER TO "matrix-synapse";
            '';
            dataDir = "/var/lib/postgres";
            authentication = pkgs.lib.mkOverride 10 ''
              #type database  DBuser  auth-method
              local all       all     trust
            '';
          };
          # enable synapse
          services.matrix-synapse = {
            enable = true;
            settings = with config.services.coturn; {
              enable_registration = true;
              enable_registration_without_verification = true;
              turn_uris = [ "turn:${realm}:3478?transport=udp" "turn:${realm}:3478?transport=tcp" ];
              turn_shared_secret = static-auth-secret-file;
              turn_user_lifetime = "1h";
              listeners = [
                {
                  port = 8008;
                  bind_addresses = [ "0.0.0.0" ];
                  type = "http";
                  tls = false;
                  x_forwarded = true;
                  resources = [{
                    names = [ "client" "federation" ];
                    compress = true;
                  }];
                }
              ];
            };
          };
          # enable coturn
          services.coturn = rec {
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
          # open the firewall
          networking.firewall =
            let
              range = with config.services.coturn; lib.singleton {
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
        };
      };

    };
}
