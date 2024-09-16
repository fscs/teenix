{ lib
, pkgs
, host-config
, config
, ...
}:
{
  # enable postgres
  services.postgresql = {
    enable = true;
    ensureDatabases = [
      "matrix-auth"
    ];
    ensureUsers = [
      {
        name = "matrix-auth";
        ensureDBOwnership = true;
      }
    ];
    dataDir = "/var/lib/postgres";
    authentication = pkgs.lib.mkOverride 10 ''
      local all       all     trust
      host  all       all     all trust
    '';
  };

  environment.systemPackages = [
    pkgs.unstable.matrix-authentication-service
  ];

  # open the firewall
  networking.firewall =
    {
      allowedTCPPorts = [ ];
    };

  system.stateVersion = "23.11";
}
