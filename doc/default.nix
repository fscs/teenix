{
  stdenv,
  mdbook,
  mdbook-alerts,
  mdbook-emojicodes,
  mdbook-footnote,
  mdbook-toc,
}:
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

  buildPhase = ''
    mdbook build
  '';

  installPhase = ''
    cp -r book $out
  '';

  meta.description = "doku für teenix";
})
