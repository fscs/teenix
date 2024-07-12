{ lib
, config
, ...
}: {
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
    {
      users.users =
        lib.attrsets.mapAttrs
          (_: value: {
            isNormalUser = true;
            shell = value.shell;
            #hashedPasswordFile = value.hashedPasswordFile;
	    initialPassword = "test";
            extraGroups = value.extraGroups;
          })
          opts;
    };
}
