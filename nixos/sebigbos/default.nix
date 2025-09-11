{
  lib,
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
      ipv4.addresses = lib.singleton {
        address = "134.99.147.41";
        prefixLength = 27;
      };
    };
  };

  virtualisation.vmware.guest.enable = true;

  teenix.persist.enable = true;

  teenix.services.node_exporter.enable = true;

  teenix.services.openssh.enable = true;

  virtualisation.oci-containers.backend = "docker";
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    liveRestore = false;
  };

  sops.secrets.sebigbos-root-passwd = {
    sopsFile = ../secrets/passwords.yml;
    neededForUsers = true;
  };

  users.users.root.hashedPasswordFile = config.sops.secrets.sebigbos-root-passwd.path;

  system.stateVersion = "23.11";
}
