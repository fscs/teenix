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
      http = {
        public_base = "https://matrixauth.inphima.de/";
        listeners = [
          {
            name = "web";
            resources = [
              {
                name = "discovery";
              }
              {
                name = "human";
              }
              {
                name = "oauth";
              }
              {
                name = "compat";
              }
              {
                name = "graphql";
              }
              {
                name = "assets";
                path = "${pkgs-unstable.matrix-authentication-service}/share/matrix-authentication-service/assets/";
              }
            ];
            binds = [
              {
                host = "0.0.0.0";
                port = 8080;
              }
            ];
          }
        ];
      };
      database = {
        uri = "postgresql:///matrix-authentication-service?host=/run/postgresql";
      };
    };
  };


  environment.systemPackages = [
    pkgs.python312Packages.authlib
    pkgs-unstable.matrix-authentication-service
  ];


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
    extras = [ "oidc" ];
    settings = {
      app_service_config_files = [
        "/var/lib/matrix-synapse/discord-registration.yaml"
        "/var/lib/matrix-synapse/double-puppet-registration.yaml"
      ];
      enable_metrics = true;
      serve_server_wellknown = true;
      use_appservice_legacy_authorization = true;
      default_identity_server = "https://sydent.inphima.de";
      public_baseurl = "https://matrix.inphima.de:443";
      user_directory = {
        enabled = true;
        search_all_users = true;
        prefer_local_users = true;
        show_locked_users = true;
      };
      max_upload_size = "100M";
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
      rc_invites = {
        per_room = {
          per_second = 1000;
          burst_count = 1000;
        };
        per_user = {
          per_user = 1000;
          per_second = 1000;
        };
        per_issuer = {
          per_second = 1000;
          burst_count = 1000;
        };
      };

      turn_uris = [ "turn:${config.services.coturn.realm}:30000?transport=udp" "turn:${config.services.coturn.realm}:30000?transport=tcp" ];
      turn_shared_secret = "memes";
      turn_user_lifetime = "1h";

      extra_well_known_client_content = {
        "org.matrix.msc3575.proxy" = {
          url = "https://syncv3.inphima.de";
        };
      };
      server_name = "${opts.servername}";

      listeners = [
        {
          port = 8008;
          bind_addresses = [ "0.0.0.0" ];
          type = "http";
          tls = false;
          x_forwarded = true;
          resources = [
            {
              names = [ "metrics" "client" "federation" ];
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
    min-port = 30001;
    max-port = 30010;
    use-auth-secret = true;
    static-auth-secret-file = "/run/secrets/matrix_pass";
    realm = "matrix.inphima.de";
    extraConfig = ''
      turn_allow_guests: true
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
      allowedTCPPorts = [ 80 443 8008 8080 3478 5349 ];
    };

  system.stateVersion = "23.11";
}
