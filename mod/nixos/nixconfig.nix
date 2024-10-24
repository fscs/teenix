{ inputs
, outputs
, lib
, config
, pkgs
, ...
}: {
  imports = [
    inputs.flake-programs-sqlite.nixosModules.programs-sqlite
  ];

  options.teenix.nixconfig = {
    enable = lib.mkOption {
      description = "auto configure nix";
      type = lib.type.bool;
      default = true;
    };
    allowUnfree = lib.mkEnableOption "allow unfree packages";
    enableChannels = lib.mkEnableOption "enable channels";
  };

  config =
    let
      opts = config.teenix.nixconfig;
    in
    {
      nixpkgs = {
        overlays = builtins.attrValues outputs.overlays;

        config.allowUnfree = opts.allowUnfree;
      };

      nix =
        let
          flakeInputs =
            lib.filterAttrs
              (_: lib.isType "flake")
              inputs;
        in
        {
          package = pkgs.nixVersions.latest;
          settings = {
            experimental-features = "nix-command flakes";
            flake-registry = "";
            nix-path = config.nix.nixPath;
          };
          channel.enable = opts.enableChannels;

          registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
          nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
        };

      programs.nh = {
        enable = true;
        clean = {
          enable = true;
          extraArgs = "--keep 15 --keep-since 14d";
        };
      };

      environment.systemPackages = with pkgs; [
        nix-output-monitor
      ];
    };
}
