{
  lib,
  config,
  host-config,
  ...
}:
{
  options.teenix.services.synapse = {
    enable = lib.mkEnableOption "synapse";
    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      description = "ugly hack to generate the template outside of the container, eww";
    };
  };

  config =
    let
      cfg = config.teenix.services.synapse;
    in
    lib.mkIf cfg.enable {
      services.postgresql = {
        enable = true;
        ensureDatabases = [ "matrix-synapse" ];
        ensureUsers = lib.singleton {
          name = "matrix-synapse";
          ensureDBOwnership = true;
        };
        authentication = ''
          local all       all     trust
        '';
      };

      teenix.services.synapse.settings = {
        registration_shared_secret = host-config.sops.placeholder.matrix-registration-secret;
        macaroon_secret_key = host-config.sops.placeholder.matrix-macaroon-secret;
        form_secret = host-config.sops.placeholder.matrix-form-secret;

        experimental_features.msc3861 = {
          enabled = true;
          issuer = "https://${host-config.teenix.services.matrix.hostnames.mas}";
          client_id = "0000000000000000000SYNAPSE";
          client_auth_method = "client_secret_basic";
          account_management_url = "https://${host-config.teenix.services.matrix.hostnames.mas}/account";
          admin_token = host-config.sops.placeholder.matrix-mas-admin-token;
          client_secret = host-config.sops.placeholder.matrix-mas-client-secret;
        };

        app_service_config_files = [
          "/var/lib/matrix-synapse/discord-registration.yaml"
          "/var/lib/matrix-synapse/double-puppet-registration.yaml"
          host-config.sops.templates.matrix-hookshot-registration-file.path
        ];

        enable_metrics = true;
        serve_server_wellknown = true;
        use_appservice_legacy_authorization = true;
        default_identity_server = "https://${host-config.teenix.services.matrix.hostnames.sydent}";
        public_baseurl = "https://${host-config.teenix.services.matrix.hostnames.matrix}:443";

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

        turn_shared_secret = host-config.sops.placeholder.matrix-turn-secret;
        turn_user_lifetime = 86400000;
        turn_allow_guests = true;
        turn_uris = [
          "turn:${config.services.coturn.realm}:30000?transport=udp"
          "turn:${config.services.coturn.realm}:30000?transport=tcp"
        ];

        server_name = host-config.teenix.services.matrix.hostnames.homeserver;

        listeners = lib.singleton {
          port = 8008;
          bind_addresses = [ "0.0.0.0" ];
          type = "http";
          tls = false;
          x_forwarded = true;
          resources = lib.singleton {
            names = [
              "metrics"
              "client"
              "federation"
            ];
            compress = false;
          };
        };
      };

      services.matrix-synapse = {
        enable = true;
        extraConfigFiles = [ host-config.sops.templates.matrix-config-file.path ];
        extras = [ "oidc" ];
      };
    };
}
