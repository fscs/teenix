{ lib
, config
, ...
}: {
  options.teenix.services.nextcloud = {
    enable = lib.mkEnableOption "setup nextcloud";
    secretsFile = lib.mkOption {
      type = lib.types.path;
      description = "path to the sops secret file for the adminPass";
    };

  };
  config =
    let
      opts = config.teenix.services.nextcloud;
    in
    lib.mkIf opts.enable {
      sops.secrets.nextcloud_pass = {
        sopsFile = opts.secretsFile;
        format = "binary";
      };
      networking = {
        bridges.br0.interfaces = [ "eno1" ]; # Adjust interface accordingly

        # Get bridge-ip with DHCP
        useDHCP = false;
        interfaces."br0".useDHCP = true;

        # Set bridge-ip static
        interfaces."br0".ipv4.addresses = [{
          address = "192.168.100.3";
          prefixLength = 24;
        }];
        defaultGateway = "192.168.100.1";
        nameservers = [ "192.168.100.1" ];
      };

      containers.nextcloud = {
        autoStart = true;
        privateNetwork = true;
        hostBridge = "br0";
        localAddress = "192.168.100.5/24";
        config = { pkgs, lib, ... }: {

          services.nextcloud = {
            enable = true;
            package = pkgs.nextcloud29;
            hostName = "localhost";
            config.adminpassFile = config.sops.secrets.nextcloud_pass.path;
          };

          system.stateVersion = "23.11";

          networking = {
            firewall = {
              enable = true;
              allowedTCPPorts = [ 80 ];
            };
            # Use systemd-resolved inside the container
            # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
            useHostResolvConf = lib.mkForce false;
          };

          services.resolved.enable = true;

        };
      };
    };
}
