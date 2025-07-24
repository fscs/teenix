{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.teenix.services.gitlab-runner = {
    enable = lib.mkEnableOption "gitlab runner";
    secretsFile = lib.teenix.mkSecretsFileOption "gitlab-runner";
  };

  config =
    let
      opts = config.teenix.services.gitlab-runner;

      runnerConfigFile = token: ''
        CI_SERVER_URL=https://git.hhu.de
        CI_SERVER_TOKEN=${token}
      '';

      placeholder = config.sops.placeholder;
    in
    lib.mkIf opts.enable {
      sops.secrets = {
        gitlab-runner-fscs-nix-1 = {
          sopsFile = opts.secretsFile;
          format = "yaml";
          key = "fscs-nix-1";
          mode = "444";
        };
        gitlab-runner-fscs-nix-2 = {
          sopsFile = opts.secretsFile;
          format = "yaml";
          key = "fscs-nix-2";
          mode = "444";
        };
        gitlab-runner-fscs-nix-3 = {
          sopsFile = opts.secretsFile;
          format = "yaml";
          key = "fscs-nix-3";
          mode = "444";
        };
        gitlab-runner-inphima-nix-1 = {
          sopsFile = opts.secretsFile;
          format = "yaml";
          key = "inphima-nix-1";
          mode = "444";
        };
      };

      sops.templates = {
        gitlab-runner-fscs-nix-1.content = runnerConfigFile placeholder.gitlab-runner-fscs-nix-1;
        gitlab-runner-fscs-nix-2.content = runnerConfigFile placeholder.gitlab-runner-fscs-nix-2;
        gitlab-runner-fscs-nix-3.content = runnerConfigFile placeholder.gitlab-runner-fscs-nix-3;

        gitlab-runner-inphima-nix-1.content = runnerConfigFile placeholder.gitlab-runner-inphima-nix-1;
      };

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
                    bash
                    curl
                    ncurses
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

          settings = {
            concurrent = 3;
          };

          services = {
            fscs-nix-1 = dockerizedNixRunner config.sops.templates.gitlab-runner-fscs-nix-1.path;
            fscs-nix-2 = dockerizedNixRunner config.sops.templates.gitlab-runner-fscs-nix-2.path;
            fscs-nix-3 = dockerizedNixRunner config.sops.templates.gitlab-runner-fscs-nix-3.path;

            inphima-nix-1 = dockerizedNixRunner config.sops.templates.gitlab-runner-inphima-nix-1.path;
          };
        };
    };
}
