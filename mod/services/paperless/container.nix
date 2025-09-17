{
  lib,
  host-config,
  config,
  ...
}:
{
  options.teenix.uglyOAuthOptionPassthrough = lib.mkOption {
    type = lib.types.anything;
  };

  config = {
    environment.systemPackages = [
      config.services.paperless.manage
    ];

    teenix.uglyOAuthOptionPassthrough = {
      openid_connect = {
        SCOPES = [
          "openid"
          "profile"
          "email"
          "first_name"
          "family_name"
          "offline_access"
          "groups"
        ];
        
        APPS = lib.singleton {
          provider_id = "authentik";
          name = "PhyNIx Login";
          client_id = "paperless";

          secret = host-config.sops.placeholder.paperless-oauth-client-secret;

          settings = {
            fetch_userinfo = true;
            server_url = "https://${host-config.teenix.services.authentik.hostname}/application/o/paperless/.well-known/openid-configuration";
            claims = {
              username = "nickname";
              first_name = "first_name";
              last_name = "family_name";
            };
          };
        };
      };
    };

    services.paperless = {
      enable = true;
      address = "0.0.0.0";

      database.createLocally = true;

      passwordFile = host-config.sops.secrets.paperless-admin-password.path;

      consumptionDirIsPublic = true;

      environmentFile = host-config.sops.templates.paperless-environment.path;

      settings = {
        PAPERLESS_URL = "https://${host-config.teenix.services.paperless.hostname}";

        PAPERLESS_APPS = lib.concatStringsSep "," [
          "allauth.socialaccount.providers.openid_connect"
        ];
        
        PAPERLESS_SOCIAL_AUTO_SIGNUP = true;
        PAPERLESS_SOCIAL_ACCOUNT_SYNC_GROUPS = true;
        # PAPERLESS_DISABLE_REGULAR_LOGIN = true;
        # PAPERLESS_REDIRECT_LOGIN_TO_SSO = true;
      };
    };

    system.stateVersion = "25.05";
  };
}
