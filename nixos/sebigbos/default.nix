{
  inputs,
  outputs,
  config,
  ...
}:
{
  imports = [
    ../share
    ./hardware-configuration.nix
    ./disko.nix
    ./services.nix
    ./nfs.nix
    ./haproxy.nix

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
        routes = [
          {
            address = "134.99.210.131";
            prefixLength = 32;
            via = "134.99.147.33";
          }
          {
            address = "192.18.0.0";
            prefixLength = 16;
            via = "134.99.147.42";
          }
          {
            address = "192.88.99.0";
            prefixLength = 24;
            via = "134.99.147.42";
          }
          {
            address = "192.168.0.0";
            prefixLength = 16;
            via = "134.99.147.43";
          }
        ];
      };
    };

    firewall = {
      checkReversePath = false;
      logRefusedConnections = true;
    };
  };

  virtualisation.vmware.guest.enable = true;

  teenix.services.node_exporter.enable = true;

  teenix.services.openssh.enable = true;

  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    liveRestore = false;
  };
  virtualisation.oci-containers.backend = "docker";

  # if this doesnt exist, traefik stops working (because sops templating refuses to work)
  sops.secrets.blub = {
    sopsFile = ../secrets/passwords.yml;
    key = "verleihnix-root-passwd";
  };

  sops.secrets.sebigbos-root-passwd = {
    sopsFile = ../secrets/passwords.yml;
    neededForUsers = true;
  };

  users.users.root.hashedPasswordFile = config.sops.secrets.sebigbos-root-passwd.path;

  system.stateVersion = "23.11";
}
