{
  inputs,
  pkgs,
  host-config,
  config,
  ...
}:
{
  imports = [
    inputs.fscshhude.nixosModules.fscs-website
    inputs.fscshhude.inputs.server.nixosModules.fscs-website-server
  ];

  services.fscs-website-setup.enable = true;

  services.fscs-website-server = {
    enable = true;
    package = inputs.fscshhude.inputs.server.packages.${pkgs.stdenv.system}.default;
    content = config.services.fscs-website-setup.dataDir;
    environmentFile = host-config.sops.secrets.fscshhude-env.path;
    authUrl = "https://${host-config.teenix.services.authentik.hostname}/application/o/authorize/";
    tokenUrl = "https://${host-config.teenix.services.authentik.hostname}/application/o/token/";
    userInfoUrl = "https://${host-config.teenix.services.authentik.hostname}/application/o/userinfo/";
  };

  system.stateVersion = "24.11";
}
