{
  lib,
  host-config,
  config,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;

  users.groups.n8n = { };
  users.users.n8n = {
    isSystemUser = true;
    group = "n8n";
  };

  systemd.services.n8n.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "n8n";
    Group = "n8n";
  };
  
  services.n8n = {
    enable = true; 
    webhookUrl = "https://${host-config.teenix.services.n8n.hostname}";

    settings = {
      generic.timezone = host-config.time.timeZone;
    };
  };
  
  system.stateVersion = "25.05";
}
