{ lib
, host-config
, ...
}: {
  networking.hostName = "ntfy";

  services.ntfy-sh = {
    enable = true;
    settings = {
      listen-http = ":8080";
      base-url = "https://${host-config.teenix.services.ntfy.hostname}";
      auth-default-access = "deny-all";
      auth-file = "/var/lib/ntfy/user.db";
    };
  };

  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 8080 ];
    };
    # Use systemd-resolved inside the container
    # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
    useHostResolvConf = lib.mkForce false;
  };

  services.resolved.enable = true;

  system.stateVersion = "23.11";
}

