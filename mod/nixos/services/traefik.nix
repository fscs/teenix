{
  config,
  pkgs,
  lib,
  ...
}: {
  options.teenix.services.traefik = {
    enable = lib.mkEnableOption "Enable the Traefik Reverse Proxy";
    letsencryptMail = lib.mkOption {
      type = lib.types.str;
      default = null;
      description = ''
        The email address used for letsencrypt certificates
      '';
    };
    dashboardUrl = lib.mkOption {
      type = lib.types.str;
      default = null;
      description = ''
        The url to which the dashboard should be published to
      '';
    };
    entrypoints = lib.mkOption {
      type = lib.types.attrs;
      default = {
        web = {
          port = 80;
          http = {
            redirections = {
              entryPoint = {
                to = "websecure";
                scheme = "https";
              };
            };
          };
        };
        websecure = {
          port = 443;
        };
      };
      description = ''
        The entrypoints of the traefik reverse proxy default are 80 (web) and 443 (websecure)
      '';
    };
    redirects =
      lib.mkOption {};
    services = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({...}: {
        options = {
          router = {
            rule = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = ''
                The routing rule for this service. The rules are defined here: https://doc.traefik.io/traefik/routing/routers/
              '';
            };
            priority = lib.mkOption {
              type = lib.types.int;
              default = 0;
            };
            tls = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = ''
                  Enable tls for router, default = true;
                '';
              };
              options = lib.mkOption {
                type = lib.types.attrs;
                default = {
                  certResolver = "letsencrypt";
                };
                description = ''
                  Options for tls, default is to use the letsencrypt certResolver
                '';
              };
            };
            middlewares = lib.mkOption {
              type = lib.types.listOf (lib.types.str);
              default = [];
              description = ''
                The middlewares applied to the router, the middlewares are applied in order.
              '';
            };
            entryPoints = lib.mkOption {
              type = lib.types.listOf (lib.types.str);
              default = ["websecure"];
              description = ''
                The Entrypoint of the service, default is 443 (websecure)
              '';
            };
          };
          servers = lib.mkOption {
            type = lib.types.listOf (lib.types.str);
            default = [];
            description = ''
              The hosts of the service
            '';
          };
        };
      }));
      default = {};
      description = ''
        A simple setup to configure http loadBalancer services and routers.
      '';
    };
  };

  config = lib.mkIf config.teenix.services.traefik.enable {
    networking.firewall.allowedTCPPorts = lib.attrsets.mapAttrsToList (name: value: value.port) config.teenix.services.traefik.entrypoints;

    services.traefik = {
      enable = true;
      dynamicConfigOptions = {
        http = {
          middlewares = {
            test-auth = {
              forwardAuth = {
                address = "https://auth.fscs-hhu.de/";
                trustForwardHeader = true;
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
          routers =
            lib.attrsets.mapAttrs
            (
              name: value:
                lib.mkMerge [
                  {
                    rule = value.router.rule;
                    priority = value.router.priority;
                    middlewares = value.router.middlewares;
                    service = name;
                    entryPoints = value.router.entryPoints;
                  }
                  (lib.mkIf value.router.tls.enable {
                    tls = value.router.tls.options;
                  })
                ]
            )
            config.teenix.services.traefik.services;
          services =
            lib.attrsets.mapAttrs
            (name: value: {
              loadBalancer = {
                servers = builtins.map (value: {url = value;}) value.servers;
              };
            })
            config.teenix.services.traefik.services;
        };
      };

      staticConfigOptions = {
        metrics.prometheus = {
          entryPoint = "metrics";
        };
        certificatesResolvers = {
          letsencrypt = {
            acme = {
              email = config.teenix.services.traefik.letsencryptMail;
              storage = "/var/lib/traefik/acme.json";
              tlsChallenge = {};
            };
          };
        };

        entryPoints =
          lib.attrsets.filterAttrs (n: v: n != "port")
          (lib.attrsets.mapAttrs
            (name: value:
              lib.attrsets.mergeAttrsList [
                {
                  address = ":${toString value.port}";
                }
                value
                {
                  port = null;
                }
              ])
            config.teenix.services.traefik.entrypoints);

        api = {
          dashboard = true;
        };
      };
    };
  };
}
