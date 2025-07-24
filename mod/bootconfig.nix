{
  lib,
  config,
  ...
}:
{
  options.teenix.bootconfig = {
    enable = lib.mkEnableOption "auto configure the boot loader";
  };

  config =
    let
      opts = config.teenix.bootconfig;
    in
    lib.mkIf opts.enable {
      boot.loader.grub = {
        enable = true;
        device = "/dev/sda";
        efiSupport = false;
      };
    };
}
