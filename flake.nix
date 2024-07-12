{
  description = "Teenix nixos config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=24.05";
    sops = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fscshhu.url = "git+ssh://git@git.hhu.de/fscs/website.git";
  };

  outputs =
    { self
    , nixpkgs
    , ...
    } @ inputs:
    let
      inherit (self) outputs;
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      lib = nixpkgs.lib;

      forAllSystems = lib.genAttrs systems;

      mkSystem = hostname: {
        "${hostname}" = lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [ ./nixos/${hostname} ];
        };
      };

      devShell =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default =
            with pkgs;
            mkShell {
              sopsPGPKeyDirs = [
                "${toString ./.}/nixos/keys/hosts"
                "${toString ./.}/nixos/keys/users"
              ];

              nativeBuildInputs = [
                (pkgs.callPackage inputs.sops { }).sops-import-keys-hook
              ];
            };
        };

      genSystems = hostnames:
        builtins.foldl' lib.trivial.mergeAttrs { } (builtins.map mkSystem hostnames);
    in
    {
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

      packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
      overlays = import ./overlays.nix { inherit inputs; };

      nixosModules.teenix = import ./mod/nixos;

      nixosConfigurations = genSystems [ "teefax" ];

      devShells = forAllSystems devShell;
    };
}
