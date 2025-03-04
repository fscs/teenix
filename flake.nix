{
  description = "Teefax NixOS config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; # NOTE: change channel in gitlab runner when updating this
    nixpkgs-master.url = "github:nixos/nixpkgs";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";

    colmena.url = "github:zhaofengli/colmena";
    flake-programs-sqlite = {
      url = "github:wamserma/flake-programs-sqlite";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix.url = "github:Mic92/sops-nix";
    nix-tun.url = "github:nix-tun/nixos-modules";
    authentik-nix.url = "github:nix-community/authentik-nix";

    discord-intern-bot.url = "git+ssh://git@git.hhu.de/fscs/discord-intern-bot.git";
    discord-inphima-bot.url = "git+ssh://git@git.hhu.de/inphima/inphima-discord-bot.git";
    matrix-intern-bot.url = "git+ssh://git@git.hhu.de/fscs/matrix-bot.git";
    fscshhude.url = "git+ssh://git@git.hhu.de/fscs/website.git";
    campus-guesser-server.url = "git+ssh://git@git.hhu.de/fscs/campus-guesser-server.git";
    sitzungsverwaltung.url = "git+ssh://git@github.com/fscs/sitzungsverwaltung-gui";
    mete = {
      url = "github:fscs/mete/wip/fscs";
      flake = false;
    };
    grafana2ntfy.url = "github:fscs/grafana-to-ntfy";

    # follows
    discord-intern-bot.inputs.nixpkgs.follows = "nixpkgs";
    matrix-intern-bot.inputs.nixpkgs.follows = "nixpkgs";
    campus-guesser-server.inputs.nixpkgs.follows = "nixpkgs";
    grafana2ntfy.inputs.nixpkgs.follows = "nixpkgs";
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
      formatter = eachSystem (
        system: pkgs:
        pkgs.writers.writeBashBin "fmt" ''
          find . -type f -name \*.nix | xargs ${lib.getExe pkgs.nixfmt-rfc-style}
        ''
      );

      packages = eachSystem (
        system: pkgs:
        (import ./pkgs pkgs)
        // {
          doc = pkgs.callPackage ./doc { };
        }
      );
      overlays = import ./overlays.nix { inherit inputs; };

      nixosModules.teenix = import ./mod/nixos;

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
          deployment.targetHost = "fscs.hhu.de";
          imports = [ ./nixos/teefax ];
        };

        testfax = {
          deployment.targetHost = "dev.hhu-fscs.de";
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

      devShells = eachSystem (
        system: pkgs: {
          default = pkgs.mkShell {
            sopsPGPKeyDirs = [
              "${toString ./.}/nixos/keys/hosts"
              "${toString ./.}/nixos/keys/users"
            ];

            nativeBuildInputs =
              with pkgs;
              [
                mdbook
                mdbook-alerts
                mdbook-emojicodes
                mdbook-footnote
                mdbook-toc
                nixos-rebuild
              ]
              ++ [
                sops-nix.packages.${system}.sops-import-keys-hook
                colmena.packages.${system}.colmena
              ];
          };
        }
      );
    };
}
