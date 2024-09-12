{
  description = "Teenix nixos config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-23-11.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    hm = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-tun.url = "github:nix-tun/nixos-modules";
    fscshhude.url = "git+ssh://git@git.hhu.de/fscs/website.git";
    fscs-intern-bot.url = "git+ssh://git@git.hhu.de/fscs/discord-intern-bot.git";
    arion.url = "github:hercules-ci/arion";
    authentik-nix.url = "github:nix-community/authentik-nix";
    mete = {
      url = "github:fscs/mete/wip/fscs";
      flake = false;
    };
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
    in
    {
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);

      packages =
        forAllSystems
          (system: import ./pkgs nixpkgs.legacyPackages.${system});
      overlays = import ./overlays.nix { inherit inputs; };

      nixosModules.teenix = import ./mod/nixos;

      nixosConfigurations.teefax = lib.nixosSystem {
        specialArgs = { inherit inputs outputs; };
        modules = [ ./nixos/teefax ];
      };

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            sopsPGPKeyDirs = [
              "${toString ./.}/nixos/keys/hosts"
              "${toString ./.}/nixos/keys/users"
            ];

            nativeBuildInputs = [
              (pkgs.callPackage inputs.sops { }).sops-import-keys-hook
              pkgs.nixos-rebuild
            ];
          };
        }
      );
    };
}
