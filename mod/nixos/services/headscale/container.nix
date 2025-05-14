{
  host-config,
  ...
}:
{
  users.users.headscale.uid = 666;
  services.headscale = {
    enable = true;
    address = "0.0.0.0";
    port = 8080;
    settings = {
      server_url = "https://${host-config.teenix.services.headscale.hostname}";
      dns = {
        magic_dns = true;
        base_domain = "phynix-hhu";
      };
      oidc = {
        issuer = "https://auth.phynix-hhu.de/application/o/vpn/";
        client_secret_path = host-config.sops.secrets.headscale-oauth-client-secret.path;
        client_id = "I4ZtMh05gyOOkIZ8t3fuBTus9yWhfYK6OWDzwCRd";
        scope = [
          "openid"
          "profile"
          "email"
          "offline_access"
        ];
      };
    };
  };

  system.stateVersion = "24.11";
}
