{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./meta.nix ];

  options.teenix.services.minecraft.enable = lib.mkEnableOption "minecraft server";

  config = lib.mkIf config.teenix.services.minecraft.enable {
    teenix.persist.subvolumes.minecraft = {
      owner = "minecraft";
    };

    services.minecraft-server = {
      enable = true;
      package = pkgs.papermcServers.papermc-1_21_1;
      eula = true;
      openFirewall = true;
      dataDir = "${config.teenix.persist.path}/minecraft";
      jvmOpts = "";
    };
  };
}
