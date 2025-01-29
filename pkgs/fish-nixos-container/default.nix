{ stdenv }:
stdenv.mkDerivation (finalAttrs: {
  name = "fish-nixos-container";

  src = builtins.path {
    inherit (finalAttrs) name;
    path = ./.;
  };

  postInstall = ''
    mkdir -p $out/share/fish/
    cd $out/share/fish

    mkdir vendor_functions.d vendor_conf.d

    cp ${./nixos-container-comp.fish} vendor_functions.d/__nixos_container_complete.fish

    echo "__nixos_container_complete" > vendor_conf.d/__fish_nixos_container.fish
  '';

  meta = { };
})
