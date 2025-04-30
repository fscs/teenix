{
  inputs,
  outputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../share
    ./hardware-configuration.nix

    outputs.nixosModules.teenix
  ];

  environment.enableAllTerminfo = true;
  environment.systemPackages = [
    pkgs.git
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];

  networking = {
    hostName = "verleihnix";

    nameservers = [ "134.99.128.2" ];

    defaultGateway = {
      address = "134.99.147.225";
      interface = "ens160";
    };

    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "ens160";
      # Lazy IPv6 connectivity for the container
      enableIPv6 = true;
    };

    interfaces.ens160 = {
      ipv4 = {
        addresses = [
          {
            address = "134.99.147.245";
            prefixLength = 27;
          }
        ];
      };
    };

    interfaces.ens192 = {
      ipv4 = {
        addresses = [
          {
            address = "134.99.147.43";
            prefixLength = 27;
          }
        ];
        routes = lib.singleton {
          address = "134.99.210.131";
          prefixLength = 32;
          via = "134.99.147.33";
        };
      };
    };

    firewall = {
      checkReversePath = false;
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
    dashboardUrl = "traefik.dev.hhu-fscs.de";
    letsencryptMail = "fscs@hhu.de";
    logging.enable = true;
  };

  teenix.services.node_exporter.enable = true;

  teenix.services.uptime-kuma = {
    enable = true;
    hostname = "uptime.dev.hhu-fscs.de";
  };

  teenix.services.ntfy = {
    enable = true;
    hostname = "ntfy.dev.hhu-fscs.de";
  };

  sops.secrets.verleihnix-root-passwd = {
    sopsFile = ../secrets/passwords.yml;
    neededForUsers = true;
  };

  users.users.root.hashedPasswordFile = config.sops.secrets.verleihnix-root-passwd.path;

  teenix.services.minecraft.enable = true;

  system.stateVersion = "23.11";
}
