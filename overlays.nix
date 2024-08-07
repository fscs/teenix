{ inputs, ... }: {
  additions = final: _prev: import ./pkgs final.pkgs;
  unstable = final: _prev: {
    unstable = inputs.nixpkgs-unstable.legacyPackages.${final.pkgs.stdenv.hostPlatform.system};
  };
  traefik = final: _prev: {
    traefik = inputs.nixpkgs-23-11.legacyPackages.${final.pkgs.stdenv.hostPlatform.system};
  };
}
