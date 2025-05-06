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
    ./disko.nix

    inputs.disko.nixosModules.disko
    outputs.nixosModules.teenix
  ];

  networking = {
    hostName = "sebigbos";

    nameservers = [ "134.99.128.2" ];

    defaultGateway = {
      address = "134.99.147.33";
      interface = "ens33";
    };

    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "ens33";
      # Lazy IPv6 connectivity for the container
      enableIPv6 = true;
    };

    interfaces.ens33 = {
      ipv4 = {
        addresses = [
          {
            address = "134.99.147.41";
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

  teenix.services.openssh.enable = true;

  # Services
  teenix.persist.enable = true;

  teenix.services.traefik = {
    enable = true;

    letsencryptMail = "fscs@hhu.de";

    dashboard = {
      enable = true;
      url = "traefik.sebigbos.hhu-fscs.de";
    };
  };

  teenix.services.node_exporter.enable = true;

  teenix.services.ntfy = {
    enable = true;
    hostname = "ntfy.sebigbos.hhu-fscs.de";
  };

  sops.secrets.sebigbos-root-passwd = {
    sopsFile = ../secrets/passwords.yml;
    neededForUsers = true;
  };

  users.users.root.hashedPasswordFile = config.sops.secrets.sebigbos-root-passwd.path;

  system.stateVersion = "23.11";
}
