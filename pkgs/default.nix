pkgs: {
  # pkg = pkgs.callPackage ./pkg.nix {};
  voltwarden-webvault = import ./voltwarden-webvault pkgs;
  crabrave-fit-frontend = import ./crabrave-fit-frontend pkgs;
}
