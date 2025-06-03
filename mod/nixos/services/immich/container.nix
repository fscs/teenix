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
    settings = {
      server.externalDomain = "https://${host-config.teenix.services.immich.hostname}";
<<<<<<< Updated upstream
    };
    environment.IMMICH_IGNORE_MOUNT_CHECK_ERRORS = true; # The checks don't work preventing the server from start.
=======
      oauth = {
        autoLaunch = false;
        autoRegister = true;
        buttonText = "Login with PhyNIx";
        clientId = "jWLpBVcaG5A50lKMvkD3SMwHjuj2dci0k0S1ciqm";
        defaultStorageQuota = 0;
        enabled = true;
        issuerUrl = "https://auth.phynix-hhu.de/application/o/immich/";
        mobileOverrideEnabled = false;
        scope = "openid email profile offline_access";
        signingAlgorithm = "RS256";
        storageLabelClaim = "preferred_username";
      };
    };
    environment.IMMICH_IGNORE_MOUNT_CHECK_ERRORS = "true"; # The checks don't work preventing the server from start.
>>>>>>> Stashed changes
  };

  #Tries to chown in netapp, this is forbidden
  systemd.services.immich-server.serviceConfig.StateDirectory = lib.mkForce null;

  system.stateVersion = "25.05";
}
