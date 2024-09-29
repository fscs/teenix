{ lib
, pkgs
, host-config
, pkgs-unstable
, config
, ...
}:
let
  opts = host-config.teenix.services.matrix;
in
{
  imports = [
    ./mas.nix
  ];

  teenix.services.mas = {
    enable = true;
    secretFile = host-config.sops.secrets.masSecrets.path;
    settings = {
      passwords.enabled = false;
      matrix = {
        homeserver = "inphima.de";
        endpoint = "http://localhost:8008/";
      };
      database = {
        uri = "postgres://matrix-authentication-service";
      };
    };
  };

  # enable postgres
  services.postgresql = {
    enable = true;
    ensureDatabases = [
      "matrix-synapse"
      "matrix-authentication-service"
    ];
    initdbArgs = [
      "--locale=C --encoding utf8"
    ];
    ensureUsers = [
      {
        name = "matrix-authentication-service";
        ensureDBOwnership = true;
      }
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
    extraConfigFiles = [ host-config.sops.secrets.matrix_env.path ];
    settings = {
      app_service_config_files = [
        "/var/lib/matrix-synapse/discord-registration.yaml"
        "/var/lib/matrix-synapse/double-puppet-registration.yaml"
      ];
      serve_server_wellknown = true;
      use_appservice_legacy_authorization = true;
      default_identity_server = "https://sydent.inphima.de";
      public_baseurl = "https://inphima.de";
      user_directory = {
        enabled = true;
        search_all_users = true;
        prefer_local_users = true;
        show_locked_users = true;
      };
      rc_joins = {
        local = {
          per_second = 1000;
          burst_count = 15;
        };
        remote = {
          per_second = 300;
          burst_count = 12;
        };
      };

      extra_well_known_client_content = {
        "org.matrix.msc3575.proxy" = {
          url = "https://syncv3.inphima.de";
        };
      };

      turn_uris = [ "turn:${config.services.coturn.realm}:3478?transport=udp" "turn:${config.services.coturn.realm}:3478?transport=tcp" ];
      turn_shared_secret = config.services.coturn.static-auth-secret-file;
      turn_user_lifetime = "1h";
      server_name = "${opts.servername}";
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
              compress = false;
            }
          ];
        }
      ];
    };
  };

  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];

  environment.systemPackages = [
    pkgs-unstable.mautrix-discord
  ];

  systemd.services."mautrix-discord" = {
    description = "Start mautrix discord";
    after = [ "network.target" ];
    path = [ pkgs.bash ];
    serviceConfig = {
      Type = "exec";
      User = "matrix-synapse";
      WorkingDirectory = "/var/lib/matrix-synapse";
      ExecStart = "${pkgs-unstable.mautrix-discord}/bin/mautrix-discord";
      Restart = "always";
      RestartSec = 5;
    };
    wantedBy = [ "multi-user.target" ];
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

  # open the firewall
  networking.firewall =
    let
      range =
        lib.singleton
          {
            from = config.services.coturn.min-port;
            to = config.services.coturn.max-port;
          };
    in
    {
      allowedUDPPortRanges = range;
      allowedUDPPorts = [ 3478 5349 ];
      allowedTCPPortRanges = [ ];
      allowedTCPPorts = [ 80 443 8008 3478 5349 ];
    };

  system.stateVersion = "23.11";
}
