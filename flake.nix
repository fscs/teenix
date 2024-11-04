{
  description = "Teefax NixOS config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; #NOTE: change channel in gitlab runner when updating this
    nixpkgs-master.url = "github:nixos/nixpkgs";

    sops = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-programs-sqlite = {
      url = "github:wamserma/flake-programs-sqlite";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-tun = {
      url = "github:nix-tun/nixos-modules";
      inputs.nixpkgs.follows = "nixpkgs"; # uses unstable internally
    };
    authentik-nix = {
      url = "github:nix-community/authentik-nix";
      inputs.nixpkgs.follows = "nixpkgs"; # uses unstable internally
    };

    discord-intern-bot = {
      url = "git+ssh://git@git.hhu.de/fscs/discord-intern-bot.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fscshhude = {
      url = "git+ssh://git@git.hhu.de/fscs/website.git";
      inputs.nixpkgs.follows = "nixpkgs"; # needs hugo 134
    };
    mete = {
      url = "github:fscs/mete/wip/fscs";
      flake = false;
    };
    campus-guesser-server.url = "git+ssh://git@git.hhu.de/fscs/campus-guesser-server.git";
    sitzungsverwaltung.url = "github:fscs/sitzungsverwaltung-gui";
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-master
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
        specialArgs = {
          pkgs-master = import nixpkgs-master {
            system = "x86_64-linux";
          };
        };
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
