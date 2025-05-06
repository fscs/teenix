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

  teenix.persist.subvolumes.system.directories = {
    "/var/lib/fail2ban" = {
      mode = "0750";
    };
  };

  services.fail2ban = {
    enable = true;
    ignoreIP = [ "134.99.0.0/16" ];
    bantime-increment.enable = true;
  };

  networking = {
    hostName = "teefax";

    nameservers = [
      "134.99.154.201"
      "134.99.154.228"
    ];

    defaultGateway = {
      address = "134.99.154.1";
      interface = "ens32";
    };

    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "ens32";
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

    firewall = {
      checkReversePath = false;
      logRefusedConnections = true;
      allowedTCPPorts = [
        2121
        2377
      ];
      allowedUDPPortRanges = [
        {
          from = 30000;
          to = 30010;
        }
      ];
      allowedTCPPortRanges = [
        {
          from = 3000;
          to = 3100;
        }
      ];
    };
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
