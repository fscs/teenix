{
  lib,
  inputs,
  outputs,
  config,
  host-config,
  ...
}:
{
  imports = [
    ../share
    ./hardware-configuration.nix
    ./disko.nix
    ./services.nix

    inputs.disko.nixosModules.disko
    outputs.nixosModules.teenix
  ];

  networking = {
    hostName = "sebigbos";

    nameservers = [ "9.9.9.9" ];

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
      ipv4.routes = lib.singleton {
        address = "192.168.10.0";
        prefixLength = 24;
        via = "134.99.147.40";
      };
    };

    firewall.checkReversePath = false;
  };

  services.tailscale.enable = true;

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
