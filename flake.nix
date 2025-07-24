{
  description = "Teefax NixOS config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; # NOTE: change channel in gitlab runner when updating this
    nixpkgs-master.url = "github:nixos/nixpkgs";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    # when updating, check that fscshhude still builds
    # correctly (check custom code blocks)

    colmena.url = "github:zhaofengli/colmena";
    flake-programs-sqlite = {
      url = "github:wamserma/flake-programs-sqlite";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko.url = "github:nix-community/disko";

    sops-nix.url = "github:Mic92/sops-nix";
    impermanence.url = "github:nix-community/impermanence";
    authentik-nix.url = "github:nix-community/authentik-nix";

    discord-inphima-bot.url = "git+ssh://git@git.hhu.de/inphima/inphima-discord-bot.git";
    matrix-intern-bot.url = "git+ssh://git@git.hhu.de/fscs/matrix-bot.git";
    fscshhude.url = "git+ssh://git@git.hhu.de/fscs/website.git";
    campus-guesser-server.url = "git+ssh://git@git.hhu.de/fscs/campus-guesser-server.git";
    sitzungsverwaltung.url = "git+ssh://git@git.hhu.de/fscs/sitzungsverwaltung";
    grafana2ntfy.url = "github:fscs/grafana-to-ntfy";
    fscs-monitor-plus.url = "github:fscs/fscs-monitor-plus";
    was-letzte-tuer.url = "github:fscs/was-letzte-tuer";
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";

    # follows
    campus-guesser-server.inputs.nixpkgs.follows = "nixpkgs";
    colmena.inputs.nixpkgs.follows = "nixpkgs";
    discord-inphima-bot.inputs.nixpkgs.follows = "nixpkgs";
    fscshhude.inputs.nixpkgs.follows = "nixpkgs-stable"; # hugo on unstable is broken
    grafana2ntfy.inputs.nixpkgs.follows = "nixpkgs";
    matrix-intern-bot.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    was-letzte-tuer.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-master,
      nixpkgs-stable,
      sops-nix,
      colmena,
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

      lib = nixpkgs.lib.extend (
        final: prev: {
          teenix = import ./lib { lib = prev; };
        }
      );

      eachSystem = f: lib.genAttrs systems (system: f system nixpkgs.legacyPackages.${system});

      specialArgs = {
        inherit inputs outputs lib;
        pkgs-master = import nixpkgs-master {
          system = "x86_64-linux";
        };
        pkgs-stable = import nixpkgs-stable {
          system = "x86_64-linux";
        };
      };
    in
    {
      formatter = eachSystem (_: pkgs: pkgs.nixfmt-tree);

      overlays = import ./overlays.nix { inherit inputs; };
      packages = eachSystem (
        system: pkgs:
        (import ./pkgs pkgs)
        // {
          doc = pkgs.callPackage ./doc {
            inherit lib;
            teenix-module = self.nixosModules.teenix;
            teenix-specialArgs = specialArgs;
          };
        }
      );

      nixosModules.teenix = import ./mod;

      colmenaHive = colmena.lib.makeHive self.outputs.colmena;
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
          deployment.targetHost = "teefax.hhu-fscs.de";
          imports = [ ./nixos/teefax ];
        };

        verleihnix = {
          deployment.targetHost = "verleihnix.hhu-fscs.de";
          imports = [ ./nixos/verleihnix ];
        };

        sebigbos = {
          deployment.targetHost = "sebigbos.hhu-fscs.de";
          imports = [ ./nixos/sebigbos ];
        };
      };

      nixosConfigurations.sebigbos = lib.nixosSystem {
        inherit specialArgs;
        modules = [ ./nixos/sebigbos ];
      };

      nixosConfigurations.teefax = lib.nixosSystem {
        inherit specialArgs;
        modules = [ ./nixos/teefax ];
      };

      nixosConfigurations.verleihnix = lib.nixosSystem {
        inherit specialArgs;
        modules = [ ./nixos/verleihnix ];
      };

      devShells = eachSystem (
        system: pkgs: {
          default = pkgs.mkShell {
            sopsPGPKeyDirs = [
              "${toString ./.}/nixos/keys/hosts"
              "${toString ./.}/nixos/keys/users"
            ];

            nativeBuildInputs = [
              sops-nix.packages.${system}.sops-import-keys-hook
              colmena.packages.${system}.colmena
            ];
          };

          mdbook = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              mdbook
              mdbook-alerts
              mdbook-emojicodes
              mdbook-footnote
              mdbook-toc
            ];
          };
        }
      );
    };
}
