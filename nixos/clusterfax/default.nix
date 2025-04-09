{
  inputs,
  outputs,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../share
    ./hardware-configuration.nix

    inputs.sops-nix.nixosModules.sops

    outputs.nixosModules.teenix
  ];

  environment.enableAllTerminfo = true;

  networking = {
    hostName = "clusterfax";

    nameservers = [ "134.99.128.2" ];

    defaultGateway = {
      address = "134.99.147.33";
      interface = "ens33";
    };

    interfaces.ens33 = {
      ipv4 = {
        addresses = [
          {
            address = "134.99.147.43";
            prefixLength = 27;
          }
        ];
      };
    };

    firewall = {
      logRefusedConnections = true;
    };
  };

  virtualisation.vmware.guest.enable = true;

  teenix.bootconfig.enable = true;

  teenix.services.openssh.enable = true;

  # Services
  teenix.persist.enable = true;

  sops.secrets.traefik = {
    format = "binary";
    mode = "444";
    sopsFile = ../secrets/traefik;
  };

  teenix.services.traefik = {
    enable = true;
    staticConfigPath = ../secrets/traefik_static;
    dashboardUrl = "traefik.ha.hhu-fscs.de";
    letsencryptMail = "fscs@hhu.de";
    logging.enable = true;
  };

  teenix.services.traefik.services."element-web" = {
    router.rule = "Host(`element.ha.hhu-fscs.de`)";
    servers = [ "http://134.99.147.42" ];
  };

  teenix.services.minecraft.enable = true;

  system.stateVersion = "23.11";
}
