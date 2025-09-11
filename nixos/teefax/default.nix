{
  outputs,
  config,
  lib,
  ...
}:
{
  imports = [
    ../share
    ./hardware-configuration.nix
    ./traefik.nix
    ./services.nix
    ./gatus.nix

    outputs.nixosModules.teenix
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];

  networking = {
    hostName = "teefax";

    nameservers = [
      "134.99.128.2"
    ];

    defaultGateway = {
      address = "134.99.147.33";
      interface = "ens34";
    };

    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "ens34";
      # Lazy IPv6 connectivity for the container
      enableIPv6 = true;
    };

    interfaces.ens34 = {
      ipv4 = {
        addresses = lib.singleton {
          address = "134.99.147.42";
          prefixLength = 27;
        };
        routes = lib.singleton {
          address = "134.99.210.131";
          prefixLength = 32;
          via = "134.99.147.33";
        };
      };
    };

    firewall.logRefusedConnections = true;
  };

  sops.secrets.teefax-root-passwd = {
    sopsFile = ../secrets/passwords.yml;
    neededForUsers = true;
  };

  virtualisation.docker = {
    enable = true;
    liveRestore = false;
  };

  users.users.root.hashedPasswordFile = config.sops.secrets.teefax-root-passwd.path;

  virtualisation.vmware.guest.enable = true;

  teenix.bootconfig.enable = true;

  teenix.services.openssh.enable = true;

  teenix.persist.enable = true;

  system.stateVersion = "23.11";
}
