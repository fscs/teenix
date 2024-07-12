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
      networking.nat = {
        enable = true;
        internalInterfaces = [ "ve-+" ];
        externalInterface = "eno1";
        # Lazy IPv6 connectivity for the container
        enableIPv6 = true;
      };
      containers.nextcloud = {
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.100.10";
        localAddress = "192.168.100.11";
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
