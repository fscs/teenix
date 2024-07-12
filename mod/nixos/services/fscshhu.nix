{ lib
, config
, fscshhu
, ...
}: {
  options.teenix.services.fscshhu.enable = lib.mkEnableOption "setup nextcloud";

  config = lib.mkIf config.teenix.services.fscshhu.enable {
    environment.systemPackages = [
      fscshhu.packages.serve
    ];
  };
}
