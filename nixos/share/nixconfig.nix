{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    inputs.flake-programs-sqlite.nixosModules.programs-sqlite
  ];

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;

    config.allowUnfree = true;
  };

  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      package = pkgs.nixVersions.latest;
      settings = {
        experimental-features = "nix-command flakes cgroups auto-allocate-uids";
        flake-registry = "";
        nix-path = config.nix.nixPath;
        auto-allocate-uids = true;
        use-cgroups = true;
      };

      channel.enable = false;

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
}
