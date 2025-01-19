{
  config,
  lib,
  ...
}:
{
  options.teenix.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          sshKeys = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Public SSH keys for the user";
          };
          shell = lib.mkOption {
            type = lib.types.shellPackage;
            default = config.users.defaultUserShell;
          };
          extraOptions = lib.mkOption {
            description = "extra options to pass to the user";
            type = lib.types.attrs;
            default = { };
          };
        };
      }
    );
    default = { };
  };

  config = {
    users.users = lib.mapAttrs (
      name: value:
      {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          (lib.mkIf config.virtualisation.docker.enable "docker")
        ];
        shell = value.shell;
        openssh.authorizedKeys.keys = value.sshKeys;
      }
      // value.extraOptions
    ) config.teenix.users;
  };
}
