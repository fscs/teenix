{
  config,
  pkgs,
  pkgs-stable,
  sops,
  lib,
  ...
}:
{
  options.teenix.services.traefik = {
    redirects =
      let
        redirectOpts = lib.types.submodule {
          options = {
            from = lib.mkOption {
              type = lib.types.str;
              default = "";
            };
            to = lib.mkOption {
              type = lib.types.str;
              default = "";
            };
          };
        };
      in
      lib.mkOption {
        type = lib.types.attrsOf redirectOpts;
        default = { };
      };
    logging = {
      enable = lib.mkEnableOption "enable logging";
      filePath = lib.mkOption {
        type = lib.types.str;
        default = "/var/log/traefik.log";
      };
    };
  };

  config = lib.mkIf config.teenix.services.traefik.enable {
    sops.secrets.traefik_static = {
      sopsFile = config.teenix.services.traefik.staticConfigPath;
      format = "binary";
      mode = "444";
    };

    teenix.persist.subvolumes.traefik = {
      owner = "traefik";
      group = "traefik";
      mode = "700";
    };

    services.traefik = {
      dynamicConfigOptions = {
        http = {
          routers =
            # REDIRECTS
            lib.attrsets.mapAttrs (name: value: {
              service = "blank";
              priority = 10;
              rule = "Host(`${builtins.replaceStrings [ "." ] [ "\." ] value.from}`)";
              middlewares = name;
              tls.certResolver = "letsencrypt";
              entryPoints = [ "websecure" ];
            }) config.teenix.services.traefik.redirects;

          middlewares =
            lib.attrsets.mapAttrs (name: value: {
              redirectRegex = {
                regex = "(www\\.)?${builtins.replaceStrings [ "." ] [ "\." ] value.from}/?";
                replacement = value.to;
                permanent = true;
              };
            }) config.teenix.services.traefik.redirects
            // {
              authentik.forwardAuth = {
                address = "https://auth.inphima.de/outpost.goauthentik.io/auth/traefik";
                tls.insecureSkipVerify = true;
                authResponseHeaders = [
                  "X-authentik-username"
                  "X-authentik-groups"
                  "X-authentik-email"
                  "X-authentik-name"
                  "X-authentik-uid"
                  "X-authentik-jwt"
                  "X-authentik-meta-jwks"
                  "X-authentik-meta-outpost"
                  "X-authentik-meta-provider"
                  "X-authentik-meta-app"
                  "X-authentik-meta-version"
                ];
              };
            };
        };
      };

      staticConfigOptions = {
        # unnessecary?
        serversTransport.insecureSkipVerify = true;

        # move to prometheus
        metrics.prometheus = {
          entryPoint = "metrics";
          buckets = [
            0.1
            0.3
            1.2
            5.0
          ];
          addEntryPointsLabels = true;
          addServicesLabels = true;
        };

        # dysfuncitonal?
        ping = {
          entryPoint = "ping";
        };

        # unnessecary?
        accesslog = lib.mkIf config.teenix.services.traefik.logging.enable {
          filePath = config.teenix.services.traefik.logging.filePath;
        };

        certificatesResolvers = {
          # move to fscshhude
          uniintern = {
            acme = {
              email = config.teenix.services.traefik.letsencryptMail;
              storage = "${config.services.traefik.dataDir}/hhucerts.json";
              tlsChallenge = { };
              caServer = ''$TRAEFIK_CERTIFICATESRESOLVERS_uniintern_ACME_CASERVER'';
              eab = {
                kid = ''$TRAEFIK_CERTIFICATESRESOLVERS_uniintern_ACME_EAB_KID'';
                hmacEncoded = ''$TRAEFIK_CERTIFICATESRESOLVERS_uniintern_ACME_EAB_HMACENCODED'';
              };
            };
          };
        };

        # turn server stuff?
        # {
        #   udp_30001 = {
        #     address = ":30001/udp";
        #   };
        # };

        # unnessecary?
        api = {
          debug = true;
        };
      };
    };
  };
}
