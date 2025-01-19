{ lib }:
{
  mkSecretsFileOption =
    name:
    lib.mkOption {
      type = lib.types.path;
      description = "path to the secrets file for ${name}";
    };

  mkHostnameOption = lib.mkOption {
    type = lib.types.nonEmptyStr;
  };

  importAllChildren =
    path:
    lib.pipe (builtins.readDir path) [
      (lib.filterAttrs (n: v: v == "directory" || (v == "regular" && lib.hasSuffix ".nix" n)))
      (lib.attrNames)
      (lib.remove "default.nix")
      (lib.map (name: "${path}/${name}"))
    ];
}
