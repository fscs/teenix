{ lib
, config
, pkgs
, ...
}: {
  options.teenix.services.gitlab-runner = {
    enable = lib.mkEnableOption "setup the gitlab runner";
    secretsFile = lib.mkOption {
      type = lib.types.path;
      description = "path to the sops secret file for the gitlab runner";
    };
  };

  config =
    let
      opts = config.teenix.services.gitlab-runner;
    in
    lib.mkIf opts.enable {
      sops.secrets.gitlab-runner = {
        sopsFile = opts.secretsFile;
        format = "binary";
        mode = "444";
      };

      boot.kernel.sysctl."net.ipv4.ip_forward" = true;

      virtualisation.docker.enable = true;

      services.gitlab-runner = {
        enable = true;
        services = {
          nix = with lib; {
            authenticationTokenConfigFile = config.sops.secrets.gitlab-runner.path;

            dockerImage = "alpine";

            dockerVolumes = [
              "/nix/store:/nix/store:ro"
              "/nix/var/nix/db:/nix/var/nix/db:ro"
              "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro"
            ];

            #NOTE: change channel on update of nixos version

            preBuildScript = pkgs.writeScript "setup-container" ''
              mkdir -p -m 0755 /nix/var/log/nix/drvs
              mkdir -p -m 0755 /nix/var/nix/gcroots
              mkdir -p -m 0755 /nix/var/nix/profiles
              mkdir -p -m 0755 /nix/var/nix/temproots
              mkdir -p -m 0755 /nix/var/nix/userpool
              mkdir -p -m 1777 /nix/var/nix/gcroots/per-user
              mkdir -p -m 1777 /nix/var/nix/profiles/per-user
              mkdir -p -m 0755 /nix/var/nix/profiles/per-user/root
              mkdir -p -m 0700 "$HOME/.nix-defexpr"
              . ${pkgs.nix}/etc/profile.d/nix-daemon.sh
              ${pkgs.nix}/bin/nix-channel --add https://nixos.org/channels/nixos-24.05 nixpkgs
              ${pkgs.nix}/bin/nix-channel --update nixpkgs
              ${pkgs.nix}/bin/nix-env -i ${concatStringsSep " " (with pkgs; [nix cacert git openssh])}
            '';

            environmentVariables = {
              ENV = "/etc/profile";
              USER = "root";
              NIX_REMOTE = "daemon";
              PATH = "/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin";
              NIX_SSL_CERT_FILE = "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt";
            };
          };
        };
      };
    };
}
