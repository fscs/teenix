{
  inputs,
  pkgs,
  host-config,
  config,
  ...
}:
{
  imports = [
    inputs.fscshhude.nixosModules.fscs-website
    inputs.fscshhude.inputs.server.nixosModules.fscs-website-server
  ];

  services.fscs-website-setup.enable = true;

  services.fscs-website-server = {
    enable = true;
    package = inputs.fscshhude.inputs.server.packages.${pkgs.stdenv.system}.default;

    environmentFile = host-config.sops.templates.fscshhude.path;

    calendars = {
      events = "https://nextcloud.phynix-hhu.de/remote.php/dav/public-calendars/CAx5MEp7cGrQ6cEe?export";
      branchen = "https://nextcloud.phynix-hhu.de/remote.php/dav/public-calendars/CKpykNdtKHkA6Z9B?export";
    };

    groups = {
      admin = [ "Admin" ];
      FS_Rat_Informatik = [
        "ManageSitzungen"
        "CreateAntrag"
        "ViewProtected"
      ];
      FS_Kooptiert_Informatik = [
        "CreateAntrag"
        "ViewHidden"
      ];
      FS_Dunstkreis_Informatik = [
        "CreateAntrag"
      ];
    };

    settings = {
      content-dir = config.services.fscs-website-setup.dataDir;

      oauth-source-name = "authentik";
      auth-url = "https://auth.phynix-hhu.de/application/o/authorize/";
      token-url = "https://auth.phynix-hhu.de/application/o/token/";
      user-info = "https://auth.phynix-hhu.de/application/o/userinfo/";

      cors-allowed-origin = [
        "https://sitzungen.hhu-fscs.de"
        "http://localhost:4200"
      ];
    };

  };

  system.stateVersion = "24.11";
}
