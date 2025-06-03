{
  lib,
  host-config,
  ...
}:
{
  users.users.immich.uid = 420;

  services.immich = {
    enable = true;
    host = "0.0.0.0";
    openFirewall = true;
    environment = {
      IMMICH_IGNORE_MOUNT_CHECK_ERRORS = "true"; # The checks don't work preventing the server from start.
      IMMICH_CONFIG_FILE = lib.mkForce host-config.sops.templates.immich.path;
    };
    settings = {
      server.externalDomain = "https://${host-config.teenix.services.immich.hostname}";
      newVersionCheck.enabled = false;
      oauth = {
        autoLaunch = false;
        autoRegister = true;
        buttonText = "Login with PhyNIx";
        clientId = "jWLpBVcaG5A50lKMvkD3SMwHjuj2dci0k0S1ciqm";
        clientSecret = host-config.sops.placeholder.immich-oauth-secret;
        defaultStorageQuota = 0;
        enabled = true;
        issuerUrl = "https://auth.phynix-hhu.de/application/o/immich/";
        mobileOverrideEnabled = false;
        scope = "openid email profile offline_access";
        signingAlgorithm = "RS256";
        storageLabelClaim = "preferred_username";
      };
    };
  };

  #Tries to chown in netapp, this is forbidden
  systemd.services.immich-server.serviceConfig.StateDirectory = lib.mkForce null;

  system.stateVersion = "25.05";
}
