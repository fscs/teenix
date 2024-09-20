{ inputs, ... }: {
  additions = final: _prev: import ./pkgs final.pkgs;
  unstable = final: _prev: {
    unstable = inputs.nixpkgs-unstable.legacyPackages.${final.pkgs.stdenv.hostPlatform.system};
  };
}
