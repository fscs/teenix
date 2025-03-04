{ inputs, lib, host-config, ... }:
{
  imports = [
    inputs.ultrastar-queue.nixosModules.default 
  ];

  users.users.ultrastar-queue.uid = 33;

  services.ultrastar-queue = {
    enable = true; 
    environmentFile = host-config.sops.templates.ultrastar-queue.path;
    ultraStarSongDir = "/mnt/nextcloud-data/__groupfolders/7/Karaoke/Songs";
  };

  system.stateVersion = "24.11";
}
