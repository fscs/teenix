{ lib
, config
, ...
}: {
  options.teenix.user_control.enable = lib.mkEnableOption "just for testing on other machines";
  options.teenix.users =
    let
      t = lib.types;
      userOpts = t.submodule {
        options = {
          shell = lib.mkOption {
            description = "the users shell";
            type = t.shellPackage;
          };
          extraGroups = lib.mkOption {
            type = t.nullOr (t.listOf t.str);
          };
          hashedPasswordFile = lib.mkOption {
            type = t.nullOr (t.str);
          };
        };
      };
    in
    lib.mkOption {
      type = t.attrsOf userOpts;
    };

  config =
    let
      opts = config.teenix.users;
    in
    lib.mkIf config.teenix.user_control.enable
      {
        users.users =
          lib.attrsets.mapAttrs
            (_: value: {
              isNormalUser = true;
              shell = value.shell;
              hashedPasswordFile = value.hashedPasswordFile;
              extraGroups = value.extraGroups;
            })
            opts;
      };
}
