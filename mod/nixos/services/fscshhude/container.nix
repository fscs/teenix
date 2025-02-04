{
  lib,
  inputs,
  pkgs,
  host-config,
  config,
  ...
}:
{
  users.users.fscs-website-server = {
    isNormalUser = true;
    uid = 1000; # todo: remove me
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ config.users.users.fscs-website-server.name ];
    ensureUsers = lib.singleton {
      name = config.users.users.fscs-website-server.name;
      ensureDBOwnership = true;
    };
  };

  systemd.services.fscs-website-serve = {
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    script = ''
      ${lib.getExe inputs.fscs-website-server.packages.${pkgs.stdenv.system}.default} \
        --host 0.0.0.0 \
        --port 8080 \
        --database-url "postgresql:///${config.users.users.fscs-website-server.name}?host=/run/postgresql&port=5432" \
        --content-dir "${inputs.fscshhude.packages.${pkgs.stdenv.system}.default}" \
        --auth-url "https://auth.inphima.de/application/o/authorize/" \
        --token-url "https://auth.inphima.de/application/o/token/" \
        --user-info "https://auth.inphima.de/application/o/userinfo/" \
    '';
    serviceConfig = {
      EnvironmentFile = host-config.sops.secrets.fscshhude-env.path;
      Type = "exec";
      User = config.users.users.fscs-website-server.name;
      Restart = "always";
      RestartSec = 5;
      CapabilityBoundingSet = [ "" ];
      DeviceAllow = [ "" ];
      DevicePolicy = "closed";
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      PrivateUsers = true;
      ProcSubset = "pid";
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "noaccess";
      ProtectSystem = "strict";
      RemoveIPC = true;
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      SystemCallFilter = [
        "@system-service"
        "~@privileged"
      ];
      UMask = "0077";
    };
  };

  system.stateVersion = "24.11";
}
