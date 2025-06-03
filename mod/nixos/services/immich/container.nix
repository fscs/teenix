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
    };
    environment.IMMICH_IGNORE_MOUNT_CHECK_ERRORS = true; # The checks don't work preventing the server from start.
  };

  #Tries to chown in netapp, this is forbidden
  systemd.services.immich-server.serviceConfig.StateDirectory = lib.mkForce null;

  system.stateVersion = "25.05";
}
