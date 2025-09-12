{
  lib,
  host-config,
  ...
}:
{
  services.mediamtx = {
    enable = true;
    settings = {
      api = true;
      apiAddress = "0.0.0.0:9997";
      apiTrustedProxies = [ host-config.containers.mediamtx.hostAddress ];

      rtsp = true;
      rtspTransports = [ "tcp" ];
      rtspAddress = "0.0.0.0:8554";

      paths = {
        sofas = { };
        schreibtische = { };
      };

      authInternalUsers = lib.singleton {
        user = "any";
        ips = [ "134.99.47.40" ];
        permissions = [
          { action = "publish"; }
          { action = "api"; }
        ];
      };
    };
  };

  system.stateVersion = "25.05";
}
