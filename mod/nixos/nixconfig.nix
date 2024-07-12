{ inputs
, outputs
, lib
, config
, pkgs
, ...
}: {
  options.teenix.nixconfig = {
    enable = lib.mkOption {
      description = "auto configure nix";
      type = lib.type.bool;
      default = true;
    };
    allowUnfree = lib.mkEnableOption "allow unfree packages in both home manager and nixos";
    enableChannels = lib.mkEnableOption "enable channels";
  };

  config =
    let
      opts = config.teenix.nixconfig;
    in
    {
      nixpkgs = {
        overlays = [
          outputs.overlays.additions
        ];

        config.allowUnfree = opts.allowUnfree;
      };

      nix =
        let
          flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
        in
        {
          settings = {
            experimental-features = "nix-command flakes";
            flake-registry = "";
            nix-path = config.nix.nixPath;
          };
          channel.enable = opts.enableChannels;

          registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
          nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
        };

      programs.nh.enable = true;
      programs.command-not-found.enable = false;
      programs.nix-index = {
        enable = true;
        enableFishIntegration = true;
        enableBashIntegration = true;
      };

      environment.systemPackages = with pkgs; [
        comma
        hydra-check
        nix-output-monitor
        nixpkgs-review
      ];
    };
}

