{ config
, lib
, pkgs
, ...
}:
{
  options.teenix.services.minecraft = {
    enable = lib.mkEnableOption "setup minecraft";
  };

  config =
    let
      opts = config.teenix.services.minecraft;
    in
    lib.mkIf opts.enable {
      nix-tun.storage.persist.subvolumes."minecraft" = {
        owner = "minecraft";
      };

      services.minecraft-server = {
        enable = true;
        package = pkgs.papermcServers.papermc-1_21_1;
        eula = true;
        openFirewall = true;
        dataDir = "/persist/minecraft";
        jvmOpts = "";
      };
    };
}
