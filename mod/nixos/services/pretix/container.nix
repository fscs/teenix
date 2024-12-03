{
  lib,
  host-config,
  ...
}:
let
  opts = host-config.teenix.services.pretix;
in
{
  networking = {
    hostName = "pretix";
  };

  services.pretix = {
    enable = true;
    database.createLocally = true;
    nginx.domain = opts.hostname;
    settings = {
      mail.from = "${opts.email}";
      pretix = {
        instance_name = "${opts.hostname}";
        url = "https://${opts.hostname}";
      };
    };
  };
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 80 ];
    };
    # Use systemd-resolved inside the container
    # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
    useHostResolvConf = lib.mkForce false;
  };

  system.stateVersion = "23.11";
}
