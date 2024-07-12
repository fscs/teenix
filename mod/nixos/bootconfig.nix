{ lib
, config
, ...
}: {
  options.teenix.bootconfig = {
    enable = lib.mkEnableOption "auto configure the boot loader";
  };

  config =
    let
      opts = config.teenix.bootconfig;
    in
    lib.mkIf opts.enable {
      boot.loader.systemd-boot.enable = false;
      boot.loader.efi.canTouchEfiVariables = true;
      boot.kernelParams = [ "quiet" ];

      boot.loader.grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
      };
    };
}
