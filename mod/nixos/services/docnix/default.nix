{
  lib,
  pkgs,
  config,
  outputs,
  ...
}:
{
  imports = [ ./meta.nix ];

  options.teenix.services.docnix = {
    enable = lib.mkEnableOption "serve the documentation";
    hostname = lib.teenix.mkHostnameOption "documentation";
  };

  config =
    let
      cfg = config.teenix.services.docnix;
    in
    lib.mkIf cfg.enable {
      teenix.containers.docnix = {
        config = {
          systemd.services.docnix-serve = {
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];
            script = lib.getExe outputs.packages.${pkgs.stdenv.system}.doc;
            serviceConfig = {
              Type = "exec";
              Restart = "always";
              RestartSec = 5;
            };
          };

          system.stateVersion = "24.11";
        };

        networking.ports.tcp = [ 8000 ];
      };
    };
}
