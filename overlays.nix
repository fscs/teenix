{ inputs, ... }: {
  additions = final: _prev: import ./pkgs final.pkgs;
  stable = final: _prev: {
    stable = inputs.nixpkgs-stable.legacyPackages.${final.pkgs.stdenv.hostPlatform.system};
  };
}


