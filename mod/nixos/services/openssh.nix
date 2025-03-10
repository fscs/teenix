{
  lib,
  config,
  ...
}:
{
  options.teenix.services.openssh.enable = lib.mkEnableOption "enable openssh";

  config = lib.mkIf config.teenix.services.openssh.enable {
    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
    };

    networking.firewall = {
      enable = true;
    };
  };
}
