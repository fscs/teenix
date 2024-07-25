{
  description = "Teenix nixos config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    sops = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-tun.url = "github:nix-tun/nixos-modules";
    fscshhude.url = "git+ssh://git@git.hhu.de/fscs/website.git";
    fscs-intern-bot.url = "git+ssh://git@git.hhu.de/fscs/fscs-intern-bot.git";
    arion.url = "github:hercules-ci/arion";
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
