{
  pkgs,
  lib,
  config,
  host-config,
  ...
}:
{
  options.teenix.services.mas = {
    enable = lib.mkEnableOption "matrix authentication service";
    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
    };
  };

  config =
    let
      cfg = config.teenix.services.mas;

      msc3861Config = config.services.matrix-synapse.settings.experimental_features.msc3861;
    in
    lib.mkIf cfg.enable {
      teenix.services.mas.settings = {
        passwords.enabled = false;

        matrix = {
          homeserver = host-config.teenix.services.matrix.hostnames.homeserver;
          endpoint = "http://localhost:8008/";
          secret = host-config.sops.placeholder.matrix-mas-admin-token;
        };

        clients = lib.singleton {
          client_id = msc3861Config.client_id;
          client_auth_method = msc3861Config.client_auth_method;
          client_secret = host-config.sops.placeholder.matrix-mas-client-secret;
        };

        upstream_oauth2.providers = lib.singleton {
          id = "01HFRQFT5QFMJFGF01P7JAV2ME";
          human_name = "Authentik";
          issuer = "https://${host-config.teenix.services.authentik.hostname}/application/o/matrix/";
          client_id = "2GW5dVP2f7clva2WKSkZNIiCW13TurgD3NOiqOif";
          client_secret = host-config.sops.placeholder.matrix-mas-upstream-oauth-secret;
          token_endpoint_auth_method = "client_secret_post";
          scope = "openid profile email";
          claims_imports = {
            localpart = {
              action = "require";
              template = "{{ user.preferred_username }}";
            };
            displayname = {
              action = "suggest";
              template = "{{ user.name }}";
            };
            email = {
              action = "suggest";
              template = "{{ user.email }}";
              set_email_verification = "import";
            };
          };
        };

        http = {
          public_base = "https://${host-config.teenix.services.matrix.hostnames.mas}/";
          listeners = lib.singleton {
            name = "web";
            resources = [
              { name = "discovery"; }
              { name = "human"; }
              { name = "oauth"; }
              { name = "compat"; }
              { name = "graphql"; }
              {
                name = "assets";
                path = "${pkgs.matrix-authentication-service}/share/matrix-authentication-service/assets/";
              }
            ];
            binds = lib.singleton {
              host = "0.0.0.0";
              port = 8080;
            };
          };
        };

        database.uri = "postgresql:///matrix-authentication-service?host=/run/postgresql";
      };

      services.postgresql = {
        enable = true;
        ensureDatabases = [ "matrix-authentication-service" ];
        initdbArgs = [
          "--locale=C --encoding utf8"
        ];
        ensureUsers = lib.singleton {
          name = "matrix-authentication-service";
          ensureDBOwnership = true;
        };
        authentication = lib.mkOverride 10 ''
          #type database  DBuser  auth-method
          local all       all     trust
        '';
      };

      users.users.matrix-authentication-service = {
        uid = 1444;
        group = "users";
        isSystemUser = true;
      };

      # useful for debugging
      environment.systemPackages = [ pkgs.matrix-authentication-service ];

      systemd.services.matrix-authentication-service = {
        description = "Matrix Authentication Service";
        after = [ "network.target" ];
        path = [ pkgs.bash ];
        script = ''
          ${pkgs.matrix-authentication-service}/bin/mas-cli server \
            --config=${host-config.sops.secrets.matrix-mas-encryption.path} \
            --config=${host-config.sops.templates.matrix-mas-config.path}
        '';

        serviceConfig = {
          User = config.users.users.matrix-authentication-service.name;
          WorkingDirectory = "/var/lib/matrix-auth";
          StateDirectory = "matrix-auth";
          Restart = "always";
          RestartSec = 5;
        };
        wantedBy = [ "multi-user.target" ];
      };
    };
}
