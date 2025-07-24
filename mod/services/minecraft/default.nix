{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./meta.nix
    inputs.nix-minecraft.nixosModules.minecraft-servers
  ];

  options.teenix.services.minecraft.enable = lib.mkEnableOption "minecraft server";

  config = lib.mkIf config.teenix.services.minecraft.enable {
    nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];

    teenix.persist.subvolumes.minecraft = {
      owner = "minecraft";
    };

    services.minecraft-servers = {
      enable = true;
      eula = true;
      dataDir = config.teenix.persist.subvolumes.minecraft.path;
      servers = {
        velocity = {
          enable = true;
          openFirewall = true;
          package = pkgs.velocityServers.velocity;
          jvmOpts = "-Xms1G -Xmx2G -XX:+AlwaysPreTouch -XX:+ParallelRefProcEnabled -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1HeapRegionSize=4M -XX:MaxInlineLevel=15";
          files = {
            "velocity.toml".value = {
              player-info-forwarding-mode = "legacy";

              servers = {
                campus = "localhost:25566";
                try = [ "campus" ];
              };

              forced-hosts = {
                "minecraft.fsphy.de" = [ "campus" ];
              };

              ping-passthrough = "ALL";

              announce-forge = true;
            };
          };
        };
        campus = {
          enable = true;
          package = pkgs.papermcServers.papermc-1_21_1;
          serverProperties = {
            server-port = 25566;
            online-mode = false;
            resource-pack = "https\://static.hhu-fscs.de/minecraft/hhu-4.zip";
            resource-pack-prompt = ''{"text"\:"A resource pack is required to connect to this server.","color"\:"red"}'';
            motd = "Minecraft Server der PhyNIx";
            gamemode = "adventure";
            spawn-protection = 0;
          };
          jvmOpts = "-Xms4G -Xmx6G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true";
          symlinks = {
            "spigot.yml".value = {
              settings.bungeecord = true;
            };
          };

        };
      };
    };
  };
}
