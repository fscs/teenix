{
  lib,
  host-config,
  ...
}:
{
  services.mosquitto = {
    enable = true;

    listeners = lib.singleton {
      users.knut = {
        passwordFile = host-config.sops.secrets.mosquitto-knut-password.path;
        acl = [ "readwrite #"];
      };
    };
  };

  system.stateVersion = "25.05";
}
