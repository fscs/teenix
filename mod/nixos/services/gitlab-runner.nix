{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.teenix.services.gitlab-runner = {
    enable = lib.mkEnableOption "setup the gitlab runner";
    secretsFile = lib.teenix.mkSecretsFileOption "gitlab-runner";
  };

  config =
    let
      opts = config.teenix.services.gitlab-runner;
    in
    lib.mkIf opts.enable {
      sops.secrets = {
        gitlab-runner-fscs-nix = {
          sopsFile = opts.secretsFile;
          format = "yaml";
          key = "fscs-nix";
          mode = "444";
        };
        gitlab-runner-inphima-nix = {
          sopsFile = opts.secretsFile;
          format = "yaml";
          key = "inphima-nix";
          mode = "444";
        };
      };

      sops.templates.gitlab-runner-fscs-nix.content = ''
        CI_SERVER_URL=https://git.hhu.de
        CI_SERVER_TOKEN=${config.sops.placeholder.gitlab-runner-fscs-nix}
      '';

      sops.templates.gitlab-runner-inphima-nix.content = ''
        CI_SERVER_URL=https://git.hhu.de
        CI_SERVER_TOKEN=${config.sops.placeholder.gitlab-runner-inphima-nix}
      '';

      boot.kernel.sysctl."net.ipv4.ip_forward" = true;

      virtualisation.docker.enable = true;

      services.gitlab-runner =
        let
          dockerizedNixRunner = authTokenFile: {
            authenticationTokenConfigFile = authTokenFile;

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
              ${pkgs.nix}/bin/nix-channel --add https://nixos.org/channels/nixos-unstable nixpkgs
              ${pkgs.nix}/bin/nix-channel --update nixpkgs
              ${pkgs.nix}/bin/nix-env -i ${
                lib.concatStringsSep " " (
                  with pkgs;
                  [
                    nixVersions.latest
                    cacert
                    git
                    openssh
                  ]
                )
              }
            '';

            environmentVariables = {
              ENV = "/etc/profile";
              USER = "root";
              NIX_REMOTE = "daemon";
              PATH = "/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin";
              NIX_SSL_CERT_FILE = "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt";
            };
          };
        in
        {
          enable = true;
          services = {
            fscs-nix = dockerizedNixRunner config.sops.templates.gitlab-runner-fscs-nix.path;
            inphima-nix = dockerizedNixRunner config.sops.templates.gitlab-runner-inphima-nix.path;
          };
        };
    };
}
