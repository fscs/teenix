pkgs: {
  # pkg = pkgs.callPackage ./pkg.nix {};
  fish-nixos-container = pkgs.callPackage ./fish-nixos-container { }; # ugly
  voltwarden-webvault = pkgs.callPackage ./voltwarden-webvault { };
}
