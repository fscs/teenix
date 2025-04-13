{
  stdenv,
  lib,
  mdbook,
  mdbook-alerts,
  mdbook-emojicodes,
  mdbook-footnote,
  mdbook-toc,
  simple-http-server,
  teenix-module,
  teenix-specialArgs,
  nixosOptionsDoc,
}:
let
  eval = lib.evalModules {
    modules = [
      { _module.check = false; }
      teenix-module
    ];
    specialArgs = teenix-specialArgs;
  };

  containerOptionsDoc = nixosOptionsDoc {
    options = eval.options.teenix.containers;
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "teenix-doc";
  version = "0.0.1";

  src = ./.;

  buildInputs = [
    mdbook
    mdbook-alerts
    mdbook-emojicodes
    mdbook-footnote
    mdbook-toc
  ];

  patchPhase = ''
    cat ${containerOptionsDoc.optionsCommonMark} >> src/modules/containers.md 

    sed -i '/\*Declared by:\*/,+2d' src/modules/containers.md 
  '';

  buildPhase = ''
    mkdir -p $out/bin $out/share/teenix-doc

    cat << EOF > $out/bin/teenix-doc
    #!/usr/bin/env bash
    ${lib.getExe simple-http-server} -ip "\''${1:-8000}" $out/share/teenix-doc
    EOF

    chmod +x $out/bin/teenix-doc

    mdbook build -d $out/share/teenix-doc
  '';

  meta = {
    description = "doku für teenix";
    mainProgram = "teenix-doc";
  };
})
