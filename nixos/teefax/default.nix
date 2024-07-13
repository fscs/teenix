{ inputs
, outputs
, config
, pkgs
, ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../locale.nix

    inputs.sops.nixosModules.sops

    outputs.nixosModules.teenix
  ];

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-+" ];
    externalInterface = "eno1";
    # Lazy IPv6 connectivity for the container
    enableIPv6 = true;
  };

  teenix.nixconfig.enable = true;
  teenix.bootconfig.enable = true;

  teenix.services.openssh.enable = true;

  networking.hostName = "Teefax";

  users.defaultUserShell = pkgs.fish;

  programs.fish.enable = true;

  # Services
  teenix.services.traefik = {
    enable = true;
    configFile = ../../config/traefik/config;
  };

  teenix.services.nextcloud = {
    enable = true;
    secretsFile = ../secrets/nextcloud_pass;
  };

  teenix.services.keycloak =
    {
      enable = true;
      secretsFile = ../secrets/keycloak_pass;
    };

  # Users
  teenix.user_control.enable = true;
  sops.secrets.felix_pwd = {
    format = "binary";
    sopsFile = ../secrets/felix_pwd;
    neededForUsers = true;
  };

  teenix.users.felix = {
    shell = pkgs.fish;
    extraGroups = [ "wheel" "docker" ];
    hashedPasswordFile = config.sops.secrets.felix_pwd.path;
  };

  system.stateVersion = "23.11";
}
