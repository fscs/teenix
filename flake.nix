{
  description = "Teefax NixOS config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; # NOTE: change channel in gitlab runner when updating this
    nixpkgs-master.url = "github:nixos/nixpkgs";

    flake-programs-sqlite = {
      url = "github:wamserma/flake-programs-sqlite";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops.url = "github:Mic92/sops-nix";
    nix-tun.url = "github:nix-tun/nixos-modules";
    authentik-nix.url = "github:nix-community/authentik-nix";

    discord-intern-bot.url = "git+ssh://git@git.hhu.de/fscs/discord-intern-bot.git";
    inphima-discord-bot.url = "git+ssh://git@git.hhu.de/inphima/inphima-discord-bot.git";
    matrix-intern-bot.url = "git+ssh://git@git.hhu.de/fscs/matrix-bot.git";
    fscshhude.url = "git+ssh://git@git.hhu.de/fscs/website.git";
    campus-guesser-server.url = "git+ssh://git@git.hhu.de/fscs/campus-guesser-server.git";
    sitzungsverwaltung.url = "github:fscs/sitzungsverwaltung-gui";
    mete = {
      url = "github:fscs/mete/wip/fscs";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-master,
      ...
    }@inputs:
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

      specialArgs = {
        inherit inputs outputs;
        pkgs-master = import nixpkgs-master {
          system = "x86_64-linux";
          overlays = [ self.overlays.additions ];
        };
      };
    in
    {
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);

      packages = forAllSystems (system: import ./pkgs nixpkgs-master.legacyPackages.${system});
      overlays = import ./overlays.nix { inherit inputs; };

      nixosModules.teenix = import ./mod/nixos;

      colmena = {
        meta = {
          nixpkgs = import nixpkgs { system = "x86_64-linux"; };
          inherit specialArgs;
        };

        defaults.deployment = {
          buildOnTarget = true;
          targetUser = null;
        };

        teefax = {
          deployment.targetHost = "fscs.hhu.de";
          imports = [ ./nixos/teefax ];
        };

        testfax = {
          deployment.targetHost = "minecraft.fsphy.de";
          imports = [ ./nixos/testfax ];
        };
      };

      nixosConfigurations.teefax = lib.nixosSystem {
        inherit specialArgs;
        modules = [ ./nixos/teefax ];
      };

      nixosConfigurations.testfax = lib.nixosSystem {
        inherit specialArgs;
        modules = [ ./nixos/testfax ];
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

            nativeBuildInputs = with pkgs; [
              (callPackage inputs.sops { }).sops-import-keys-hook
              nixos-rebuild
              colmena
            ];
          };
        }
      );
    };
}
