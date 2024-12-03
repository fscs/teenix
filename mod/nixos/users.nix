{
  config,
  pkgs,
  lib,
  ...
}:
{
  options = {
    teenix.users = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { ... }:
          {
            options = {
              sshKeys = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "Public SSH keys for the user";
              };
              setSopsPassword = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Whether to set the password via sops.";
              };
              shell = lib.mkOption {
                type = lib.types.shellPackage;
                default = pkgs.bash;
                description = ''
                  The shell for the user.
                '';
              };
            };
          }
        )
      );
      default = { };
    };
  };

  config = {
    sops.secrets = lib.attrsets.mapAttrs' (name: value: {
      format = "binary";
      name = "${name}-pass";
      value = {
        sopsFile = ./../../nixos/secrets + "/${name}_pwd";
        neededForUsers = true;
      };
    }) (lib.attrsets.filterAttrs (name: value: value.setSopsPassword) config.teenix.users);

    users.users = lib.attrsets.mapAttrs (name: value: {
      isNormalUser = true;
      hashedPasswordFile = lib.mkIf value.setSopsPassword config.sops.secrets."${name}-pass".path;
      extraGroups = [
        "wheel"
        (lib.mkIf config.virtualisation.docker.enable "docker")
        (lib.mkIf config.networking.networkmanager.enable "networkmanager")
      ];
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = value.sshKeys;
    }) config.teenix.users;
  };
}
