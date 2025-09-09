{
  inputs,
  host-config,
  pkgs,
  ...
}:
let
  background = pkgs.fetchurl {
    url = "https://nextcloud.phynix-hhu.de/s/Mf3Y6JqgNmxx9Wo/download";
    hash = "sha256-PKUIuEeW2IIeuYvYcOP/8QEmLNMIX986b23ria1CgTg=";
  };

  authentikComponents =
    ((inputs.authentik-nix.lib.mkAuthentikScope { inherit pkgs; }).overrideScope (
      final: prev: {
        authentikComponents = prev.authentikComponents // {
          frontend = prev.authentikComponents.frontend.overrideAttrs (oA: {
            installPhase = oA.installPhase + ''
              cp ${background} $out/dist/assets/images/flow_background.jpg
            '';
          });
        };
      }
    )).authentikComponents;
in
{
  imports = [
    inputs.authentik-nix.nixosModules.default
  ];

  services.authentik = {
    enable = true;
    environmentFile = host-config.sops.templates.authentik.path;
    createDatabase = true;

    inherit authentikComponents;

    settings = {
      email = {
        host = "mail.hhu.de";
        port = 587;
        username = "noreply-fscs";
        use_tls = true;
        use_ssl = false;
        from = "noreply-fscs@hhu.de";
      };
      disable_startup_analytics = true;
      avatars = "initials";
    };

    nginx = {
      enable = true;
      enableACME = false;
      host = "localhost";
    };

  };

  system.stateVersion = "23.11";
}
