{
  inputs,
  lib,
  pkgs,
  host-config,
  config,
  ...
}:
{
  services.crabfit = {
    enable = true;
    frontend = {
      host = host-config.teenix.services.crabfit.hostnames.frontend;
      package = pkgs.crabfit-frontend.overrideAttrs (prev: {
        patches = prev.patches ++ [
          ./privacy-policy.patch
          ./remove-vercel-analytics.patch
        ];
      });
    };
    api = {
      host = host-config.teenix.services.crabfit.hostnames.backend;
      environment.API_LISTEN = "0.0.0.0:${toString config.services.crabfit.api.port}";
    };
  };

  systemd.timers.crabfit-gc = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "daily";
  };

  systemd.services.crabfit-gc = {
    script = "${lib.getExe pkgs.curl} http://${config.services.crabfit.api.environment.API_LISTEN}/tasks/cleanup --no-progress-meter";

    serviceConfig.Type = "oneshot";
  };

  system.stateVersion = "24.11";
}
