{ lib
, config
, inputs
, pkgs
, ...
}: {
  options.teenix.services.matrix-auth = {
    enable = lib.mkEnableOption "setup inphimatrix-auth";
    hostname = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "";
    };
  };

  config =
    let
      opts = config.teenix.services.matrix-auth;
    in
    lib.mkIf opts.enable {

      nix-tun.storage.persist.subvolumes."inphimatrix-auth".directories = {
        "/postgres" = {
          owner = "${builtins.toString config.containers.inphimatrix-auth.config.users.users.postgres.uid}";
          mode = "0700";
        };
      };


      containers.inphimatrix-auth = {
        autoStart = true;
        privateNetwork = true;
        hostAddress = "192.168.113.10";
        localAddress = "192.168.113.11";
        bindMounts = {
          "resolv" = {
            hostPath = "/etc/resolv.conf";
            mountPoint = "/etc/resolv.conf";
          };
          "db" = {
            hostPath = "${config.nix-tun.storage.persist.path}/inphimatrix-auth/postgres";
            mountPoint = "/var/lib/postgres";
            isReadOnly = false;
          };
        };

        specialArgs = {
          inherit inputs pkgs;
          host-config = config;
        };

        config =
          import ./container.nix;
      };
    };
}
