{
  inputs,
  outputs,
  pkgs,
  ...
}:
{
  imports = [
    ../share
    ./hardware-configuration.nix

    inputs.sops-nix.nixosModules.sops
    inputs.nix-tun.nixosModules.nix-tun

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
    hostName = "testfax";

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

    firewall = {
      checkReversePath = false;
      logRefusedConnections = true;
    };
  };

  virtualisation.vmware.guest.enable = true;

  teenix.nixconfig.enable = true;
  teenix.nixconfig.allowUnfree = true;
  teenix.bootconfig.enable = true;

  teenix.services.openssh.enable = true;

  # Services
  nix-tun.storage.persist.enable = true;

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

  teenix.services.minecraft.enable = true;

  system.stateVersion = "23.11";
}
