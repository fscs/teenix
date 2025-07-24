{
  lib,
  config,
  host-config,
  ...
}:
{
  users.groups.gatus = { };
  users.users.gatus = {
    isSystemUser = true;
    group = "gatus";
  };

  systemd.services.gatus.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "gatus";
    Group = "gatus";
  };

  services.gatus = {
    enable = true;

    settings = {
      ui = {
        title = "Status-Page ǀ PhyNIx";
        header = "PhyNIx Status-Page";
      };

      storage = {
        type = "sqlite";
        path = "/var/lib/gatus/db.sqlite";
      };

      endpoints = lib.concatMap (
        group:
        (map (
          endpoint:
          lib.mkMerge [
            {
              inherit (endpoint) name url interval;
              group = group.name;

              conditions = lib.optional (endpoint.status != null) "[STATUS] == ${toString endpoint.status}";
            }
            endpoint.extraConfig
          ]
        ) (lib.attrValues group.endpoints))
      ) (lib.attrValues host-config.teenix.services.gatus.groups);
    };
  };

  system.stateVersion = "24.11";
}
