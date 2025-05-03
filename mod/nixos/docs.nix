{
  lib,
  options,
  pkgs,
  ...
}:
let
  t = lib.types;

  moduleType = t.submodule (
    { config, name, ... }:
    {
      options = {
        title = lib.mkOption {
          description = "human readable title for this module";
          type = t.nonEmptyStr;
        };
        description = lib.mkOption {
          description = "description of this module";
          type = t.nonEmptyStr;
        };
        mdFile = lib.mkOption {
          description = ''
            file to use as documentation

            if ommited, a default is generated from title and description
          '';
          type = t.pathInStore;
          default = pkgs.writeText "teenix-module-${name}-default.md" ''
            # ${config.title} 

            ${config.description}
          '';
        };
        optionNamespace = lib.mkOption {
          description = ''
            Option Namespace to generate documentation for
          '';
          example = [
            "teenix"
            "services"
            "fscshhude"
          ];
          type = t.nonEmptyListOf t.nonEmptyStr;
        };
        finalMarkdown = lib.mkOption {
          description = "resulting documentation file, mdFile and option doc concatenated";
          type = t.pathInStore;
          readOnly = true;
          default =
            let
              optionDoc = pkgs.nixosOptionsDoc {
                options = lib.getAttrFromPath config.optionNamespace options;
              };
            in
            pkgs.runCommandLocal "teenix-module-${name}-doc.md" { } ''
              # header
              cat ${config.mdFile} >> $out

              # option header
              cat << EOF >> $out

              ## Options
              
              EOF

              # option doc
              cat ${optionDoc.optionsCommonMark} | \
                sed -e 's/^##/###/g' -e '/\*Declared by:\*/,+2d' \
                >> $out
            '';
        };
      };
    }
  );
in
{
  options.teenix.docs = {
    modules = lib.mkOption {
      type = t.attrsOf moduleType;
    };
  };
}
