{
  stdenv,
  lib,
  mdbook,
  mdbook-alerts,
  mdbook-emojicodes,
  mdbook-footnote,
  mdbook-toc,
  caddy,
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
    cat ${containerOptionsDoc.optionsCommonMark} | \
      sed -e 's/^##/###/g' -e '/\*Declared by:\*/,+2d' \
      >> src/modules/containers.md
  '';

  buildPhase = ''
    mkdir -p $out/bin $out/share/teenix-doc

    cat << EOF > $out/bin/teenix-doc
    #!/usr/bin/env bash
    ${lib.getExe caddy} file-server -r $out/share/teenix-doc --listen ":\''${1:-8000}"
    EOF

    chmod +x $out/bin/teenix-doc

    mdbook build -d $out/share/teenix-doc
  '';

  meta = {
    description = "doku für teenix";
    mainProgram = "teenix-doc";
  };
})
