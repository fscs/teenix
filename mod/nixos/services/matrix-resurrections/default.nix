{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.teenix.services.matrix = {
    enable = lib.mkEnableOption "matrix";
    secretsFile = lib.teenix.mkSecretsFileOption "matrix";
    hostnames = {
      homeserver = lib.teenix.mkHostnameOption "homeserver name";
      matrix = lib.teenix.mkHostnameOption "matrix";
      mas = lib.teenix.mkHostnameOption "matrix authentication service";
      hookshot = lib.teenix.mkHostnameOption "hookshot";
      sydent = lib.teenix.mkHostnameOption "sydent";
      element-web = lib.teenix.mkHostnameOption "element-web";
    };
  };

  imports = [
    ./sydent.nix
    ./meta.nix
  ];

  config =
    let
      cfg = config.teenix.services.matrix;

      secrets = [
        "matrix-registration-secret"
        "matrix-mas-client-secret"
        "matrix-mas-admin-token"
        "matrix-macaroon-secret"
        "matrix-form-secret"
        "matrix-mas-encryption"
        "matrix-mas-upstream-oauth-secret"
        "matrix-turn-secret"
        "matrix-hookshot-as-token"
        "matrix-hookshot-hs-token"
      ];

      # one of the secrets contains a #, so we need to redefine the yaml generator
      # since it doesnt know about it because of templating, it also cannot escape it automatically
      yaml_generate =
        name: value:
        pkgs.runCommand name
          {
            nativeBuildInputs = [ pkgs.remarshal_0_17 ];
            value = builtins.toJSON value;
            passAsFile = [ "value" ];
            preferLocalBuild = true;
          }
          ''
            json2yaml --yaml-style \" "$valuePath" "$out"
          '';
    in
    lib.mkIf cfg.enable {
      sops.secrets = lib.genAttrs secrets (name: {
        sopsFile = cfg.secretsFile;
        key = lib.removePrefix "matrix-" name;
        mode = "0444";
      });

      sops.templates = {
        matrix-mas-config = {
          mode = "0444";
          file = yaml_generate "mas-config" config.containers.matrix.config.teenix.services.mas.settings;
        };

        matrix-config-file = {
          mode = "0444";
          file = yaml_generate "matrix-config" config.containers.matrix.config.teenix.services.synapse.settings;
        };

        matrix-hookshot-registration-file = {
          mode = "0444";
          file = yaml_generate "hookshot-registration" config.containers.matrix.config.teenix.services.matrix-hookshot.registrationSettings;
        };
      };

      # piggy backs on the matrix subvolume
      teenix.services.sydent.enable = true;

      # generate entry points for the turn server
      teenix.services.traefik.entryPoints = lib.mkMerge [
        (lib.listToAttrs (
          map (port: {
            name = "turn_port_${toString port}";
            value = {
              inherit port;
              protocol = "udp";
            };
          }) (lib.range 30001 30010)
        ))
        {
          turn_port_tcp = {
            port = 30000;
            protocol = "tcp";
          };
        }
      ];

      teenix.services.traefik.httpServices = {
        matrix = {
          router = {
            rule = "Host(`${cfg.hostnames.matrix}`) || (Host(`${cfg.hostnames.homeserver}`) && (PathPrefix(`/_matrix`) || PathPrefix(`/_synapse`) || Path(`/.well-known/matrix/server`) || Path(`/.well-known/matrix/client`)))";
            extraConfig.priority = 10000;
          };
          healthCheck = {
            enable = true;
            path = "_matrix/static/";
          };
          servers = [ "http://${config.containers.matrix.localAddress}:8008" ];
        };

        mas = {
          router = {
            rule = "Host(`${cfg.hostnames.mas}`) || (( Host(`${cfg.hostnames.matrix}`) || Host(`${cfg.hostnames.homeserver}`)) && PathRegexp(`^/_matrix/client/.*/(login|logout|refresh)`) )";
            extraConfig.priority = 10001;
          };
          healthCheck.enable = true;
          servers = [ "http://${config.containers.matrix.localAddress}:8080" ];
        };

        hookshot = {
          router.rule = "Host(`${cfg.hostnames.hookshot}`)";
          servers = [ "http://${config.containers.matrix.localAddress}:9000" ];
        };

        element-web = {
          router.rule = "Host(`${cfg.hostnames.element-web}`)";
          servers = [ "http://${config.containers.matrix.localAddress}:8000" ];
          healthCheck.enable = true;
        };
      };

      teenix.services.traefik.dynamicConfig = {
        tcp.routers.turn = {
          rule = "HostSNI(`*`)";
          service = "turn";
          priority = 10000;
        };
        tcp.services.turn = {
          loadBalancer.servers = [
            {
              address = "${config.containers.matrix.localAddress}:3478";
            }
          ];
        };

      };

      teenix.containers.matrix = {
        config = ./container.nix;

        networking = {
          useResolvConf = true;
          ports = {
            udp = [
              3478
              5349
            ] ++ (lib.range (30 * 1000) (30 * 1000 + 10)); # 30000 - 30010

            tcp = [
              3478
              443
              5349
              80
              8000
              8008
              8080
              9000
            ];
          };
        };

        mounts = {
          postgres.enable = true;

          sops = {
            inherit secrets;
            templates = [
              "matrix-mas-config"
              "matrix-config-file"
              "matrix-hookshot-registration-file"
            ];
          };

          data = {
            enable = true;
            name = "matrix-synapse";
          };

          extra = {
            mas-data = {
              mountPoint = "/var/lib/matrix-auth";
              isReadOnly = false;
            };

            media-store = {
              mountPoint = "/var/lib/matrix-synapse/media_store";
              hostPath = "/mnt/netapp/inphimatrix/media_store";
              isReadOnly = false;
            };
          };
        };
      };
    };
}
