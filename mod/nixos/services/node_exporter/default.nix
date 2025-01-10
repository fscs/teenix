{ lib
, config
, inputs
, pkgs
, ...
}:
{
  options.teenix.services.node_exporter = {
    enable = lib.mkEnableOption "setup node_exporter";
  };

  config =
    let
      opts = config.teenix.services.node_exporter;
    in
    lib.mkIf opts.enable {

      containers.node-exporter = {
        ephemeral = true;
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.115.10";
        localAddress = "192.168.115.11";
        bindMounts = {
          "resolv" = {
            hostPath = "/etc/resolv.conf";
            mountPoint = "/etc/resolv.conf";
          };
        };

        specialArgs = {
          inherit inputs;
          host-config = config;
        };

        config = import ./container.nix;
      };
    };
}
