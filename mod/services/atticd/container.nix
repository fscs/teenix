{ lib, host-config, ... }:
{
  users.groups.atticd = { };
  users.users.atticd = {
    isSystemUser = true;
    group = "atticd";
  };

  systemd.services.atticd.serviceConfig.DynamicUser = lib.mkForce false;
  services.atticd = {
    enable = true;
    environmentFile = host-config.sops.templates.atticd.path;
    settings = {
      api-endpoint = "https://${host-config.teenix.services.atticd.hostname}";
      garbage-collection.default_retention_period = "6 months";
    };
  };

  system.stateVersion = "24.11";
}
