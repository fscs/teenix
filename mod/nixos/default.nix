{
  lib,
  config,
  inputs,
  options,
  ...
}:
{
  imports = (lib.teenix.importAllChildren ./.) ++ [
    inputs.sops-nix.nixosModules.sops
  ];

  assertions = lib.singleton {
    assertion = options.system.stateVersion.highestPrio != (lib.mkOptionDefault { }).priority;
    message = "system.stateVersion is not set for ${config.networking.hostName}. this is a terrible idea, as it can cause random breakage.";
  };
}
