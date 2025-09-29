{
  lib,
  host-config,
  pkgs,
  ...
}:
{
  # ugly hack becaus mqtt is a bitch
  networking.hosts = {
    ${host-config.containers.mosquitto.localAddress} = [ "mosquitto" ];
  };

  services.home-assistant = {
    enable = true;

    extraComponents = [
      "caldav"
      "remote_calendar"
      "radio_browser"
      "isal"
    ];

    config = {
      default_config = { };

      frontend.themes = "!include_dir_merge_named themes";

      homeassistant.name = "Fachschaftsraum Informatik";

      api = {};

      recorder.exclude.entities = [
        "binary_sensor.10_bewegungsmelder_couch_occupancy"
        "binary_sensor.11_bewegungsmelder_schreibtische_occupancy"
      ];

      automation = "!include automations.yaml";
      script = "!include scripts.yaml";
      scene = "!include scenes.yaml";

      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [
          host-config.containers.home-assistant.hostAddress
          "127.0.0.1"
          "::1"
        ];
        ip_ban_enabled = false;
        login_attempts_threshold = 5;
      };

      alarm_control_panel = lib.singleton {
        platform = "manual";
        unique_id = "fscsalarm";
        name = "FSCS Raum";
        code = "!secret home-assistant-alarm-code";
        delay_time = 0;
        arming_time = 10;
        arming_states = [
          "armed_away"
        ];
      };

      shell_command = {
        tuer_auf = "${lib.getExe pkgs.curl} -X POST https://tuer.hhu-fscs.de/update?status=open";
        tuer_zu = "${lib.getExe pkgs.curl} -X POST https://tuer.hhu-fscs.de/update?status=closed";
        record = ''
          ${lib.getExe pkgs.curl} -X PATCH http://api.mediamtx.hhu-fscs.de/v3/config/paths/patch/sofas -d {"record":true}
          ${lib.getExe pkgs.curl} -X PATCH http://api.mediamtx.hhu-fscs.de/v3/config/paths/patch/schreibtische -d {"record":true}
        '';
        recordoff = ''
          ${lib.getExe pkgs.curl} -X PATCH http://api.mediamtx.hhu-fscs.de/v3/config/paths/patch/sofas -d {"record":false}
          ${lib.getExe pkgs.curl} -X PATCH http://api.mediamtx.hhu-fscs.de/v3/config/paths/patch/schreibtische -d {"record":false}
        '';
      };

      mqtt = [
        {
          button = {
            command_topic = "fscs/flur/display/reload";
            name = "Reload Flur information screen";
          };
        }
        {
          button = {
            command_topic = "fscs/sofas/display/reload";
            name = "Reload Sofaecke information screen";
          };
        }
      ];

      matrix = {
        homeserver = "https://matrix.zehka.net";
        username = "!secret home-assistant-matrix-username";
        password = "!secret home-assistant-matrix-password";
        rooms = [ "!secret home-assistant-matrix-roomid" ];
      };

      auth_oidc = {
        client_id = "homeassistant";
        client_secret = "!secret home-assistant-oauth-client-secret";
        discovery_url = "https://auth.phynix-hhu.de/application/o/homeassistant/.well-known/openid-configuration";
      };
    };
  };

  system.stateVersion = "25.05";
}
