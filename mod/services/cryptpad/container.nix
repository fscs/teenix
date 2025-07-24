{
  host-config,
  lib,
  ...
}:
{
  services.cryptpad = {
    enable = true;
    settings = {
      httpUnsafeOrigin = "https://${host-config.teenix.services.cryptpad.hostname}";
      httpSafeOrigin = "https://${host-config.teenix.services.cryptpad.hostname}";
      httpAddress = "0.0.0.0";
    };
  };
  systemd.services.cryptpad.serviceConfig.DynamicUser = lib.mkForce false;

  system.stateVersion = "25.05";
}
