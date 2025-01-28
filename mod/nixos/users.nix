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
          hosts = lib.mkOption {
            description = "list of hosts this user should be enabled on";
            type = lib.types.listOf lib.types.nonEmptyStr;
            default = [ ];
          };
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
    users.users = lib.pipe config.teenix.users [
      (lib.filterAttrs (_: v: lib.elem config.networking.hostName v.hosts))
      (lib.mapAttrs (
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
      ))
    ];

  };
}
