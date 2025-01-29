{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.teenix.services.minecraft.enable = lib.mkEnableOption "setup a minecraft server";

  config = lib.mkIf config.teenix.services.minecraft.enable {
    nix-tun.storage.persist.subvolumes.minecraft = {
      owner = "minecraft";
    };

    services.minecraft-server = {
      enable = true;
      package = pkgs.papermcServers.papermc-1_21_1;
      eula = true;
      openFirewall = true;
      dataDir = "${config.nix-tun.storage.persist.path}/minecraft";
      jvmOpts = "";
    };
  };
}
