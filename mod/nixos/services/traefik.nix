{
  config,
  pkgs,
  pkgs-stable,
  lib,
  ...
}:
{
  options.teenix.services.traefik =
    let
      t = lib.types;
    in
    {
      enable = lib.mkEnableOption "Enable the Traefik Reverse Proxy";
      letsencryptMail = lib.mkOption {
        type = t.nonEmptyStr;
        description = "The email address used for letsencrypt certificates";
      };
      dashboardUrl = lib.mkOption {
        type = t.nonEmptyStr;
        description = "The url to which the dashboard should be published to";
      };
      secretsFile = lib.teenix.mkSecretsFileOption "traefik";
      redirects = lib.mkOption {
        type = t.attrsOf t.nonEmptyStr;
      };
      dockerProvider.enable = lib.mkEnableOption {
        default = false;
        description = "Enable the docker provider for traefik";
      };
      entrypoints = lib.mkOption {
        type = pkgs.formats.yaml;
        default = { };
        description = ''
          Traefiks's entrypoints.

          80 (web) and 443 (websecure) are added by default.
        '';
      };
      accessLog = {
        enable = lib.mkEnableOption "enable traefik's accesslog";
        filePath = lib.mkOption {
          type = t.nonEmptyStr;
          default = "/var/log/traefik.log";
        };
      };
      services =
        let
          serviceOpts = t.submodule {
            options = {
              router = {
                rule = lib.mkOption {
                  type = t.str;
                  default = "";
                  description = ''
                    The routing rule for this service. The rules are defined here: https://doc.traefik.io/traefik/routing/routers/
                  '';
                };
                priority = lib.mkOption {
                  type = t.int;
                  default = 0;
                };
                tls = {
                  enable = lib.mkEnableOption {
                    default = true;
                    description = "Enable tls for the router";
                  };
                  options = lib.mkOption {
                    type = pkgs.formats.yaml;
                    default = {
                      certResolver = "letsencrypt";
                    };
                    description = ''
                      Options for tls, default is to use the letsencrypt certResolver
                    '';
                  };
                };
                middlewares = lib.mkOption {
                  type = t.listOf t.nonEmptyStr;
                  default = [ ];
                  description = ''
                    The middlewares applied to the router, the middlewares are applied in order.
                  '';
                };
                entryPoints = lib.mkOption {
                  type = t.listOf t.nonEmptyStr;
                  default = [ "websecure" ];
                  description = ''
                    The Entrypoint of the service, default is 443 (websecure)
                  '';
                };
              };
              servers = lib.mkOption {
                type = t.listOf t.nonEmptyStr;
                default = [ ];
                description = ''
                  The hosts of the service
                '';
              };
              healthCheck = {
                enable = lib.mkEnableOption "Healthcheck this service";
                path = lib.mkOption {
                  type = t.nonEmptyStr;
                  default = "/";
                  description = "Path to healthcheck on";
                };
                interval = lib.mkOption {
                  type = t.nonEmptyStr;
                  default = "10s";
                  description = "Time interval to healthcheck on";
                };
              };
            };
          };
        in
        lib.mkOption {
          type = t.attrsOf serviceOpts;
          default = { };
        };
    };

  config =
    let
      cfg = config.teenix.services.traefik;
    in
    lib.mkIf cfg.enable {
      users.users.traefik.extraGroups = [ "docker" ];

      networking.firewall.allowedTCPPorts = lib.mapAttrsToList (_: value: value.port) cfg.entrypoints;

      sops.secrets.traefik_static = {
        sopsFile = config.teenix.services.traefik.staticConfigPath;
        format = "binary";
        mode = "444";
      };

      nix-tun.storage.persist.subvolumes.traefik = {
        owner = "traefik";
        group = "traefik";
        mode = "700";
      };

      teenix.services.traefik.entrypoints = {
        web = {
          port = 80;
          http.redirections.entryPoint = {
            to = "websecure";
            scheme = "https";
          };
        };
        websecure = {
          port = 443;
        };
      };

      services.traefik =
        let

          dynamicConfig =
            pkgs.runCommand "config.toml"
              {
                buildInputs = [ pkgs.remarshal ];
                preferLocalBuild = true;
              }
              ''
                remarshal -if json -of toml \
                  < ${pkgs.writeText "dynamic_config.json" (builtins.toJSON config.services.traefik.dynamicConfigOptions)} \
                  > $out
              '';

          configDir = pkgs.runCommandLocal "traefik-config-dir" { } ''
            mkdir $out
            ln -s ${dynamicConfig} $out/dyn_config.toml
            ln -s ${config.sops.secrets.traefik.path} $out/dyn_sops.toml
          '';
        in
        {
          enable = true;
          dataDir = "${config.nix-tun.storage.persist.path}/traefik";

          package = pkgs-stable.traefik;

          environmentFiles = [ config.sops.secrets.traefik_static.path ];

          dynamicConfigOptions = {
            http = {
              routers =
                (lib.attrsets.mapAttrs (
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
                ) config.teenix.services.traefik.services)
                // lib.attrsets.mapAttrs (name: value: {
                  service = "blank";
                  priority = 10;
                  rule = "Host(`${builtins.replaceStrings [ "." ] [ "\." ] value.from}`)";
                  middlewares = name;
                  tls.certResolver = "letsencrypt";
                  entryPoints = [ "websecure" ];
                }) config.teenix.services.traefik.redirects
                // {
                  dashboard = {
                    rule = "Host(`${config.teenix.services.traefik.dashboardUrl}`)";
                    service = "api@internal";
                    entryPoints = [
                      "web"
                      "websecure"
                    ];
                    middlewares = [ "authentik" ];
                    tls.certResolver = "letsencrypt";
                  };
                };
              middlewares =
                lib.attrsets.mapAttrs (name: value: {
                  redirectRegex = {
                    regex = "(www\\.)?${builtins.replaceStrings [ "." ] [ "\." ] value.from}/?";
                    replacement = value.to;
                    permanent = true;
                  };
                }) config.teenix.services.traefik.redirects
                // {
                  meteredirect.redirectregex = {
                    regex = "https://mete.hhu-fscs.de/(.*?)((/deposit)|(/retrieve)|(/transaction))(.*)";
                    replacement = "https://mete.hhu-fscs.de/$1";
                  };
                  authentik.forwardAuth = {
                    address = "https://authentik:9443/outpost.goauthentik.io/auth/traefik";
                    trustForwardHeader = true;
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
              services =
                lib.attrsets.mapAttrs (name: value: {
                  loadBalancer = lib.mkMerge [
                    {
                      servers = builtins.map (value: {
                        url = value;
                      }) value.servers;
                    }
                    (lib.mkIf value.healthCheck.enable {
                      healthCheck = {
                        path = value.healthCheck.path;
                        interval = value.healthCheck.interval;
                      };
                    })
                  ];
                }) config.teenix.services.traefik.services
                // {
                  blank = {
                    loadBalancer = {
                      servers = {
                        url = "about:blank";
                      };
                    };
                  };
                };
            };
          };
          staticConfigOptions = {
            serversTransport.insecureSkipVerify = true;
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
            providers.file.directory = configDir;
            providers.docker = lib.mkIf config.teenix.services.traefik.withDocker {
              exposedByDefault = false;
              watch = true;
            };
            ping = {
              entryPoint = "ping";
            };
            accesslog = lib.mkIf config.teenix.services.traefik.logging.enable {
              filePath = config.teenix.services.traefik.logging.filePath;
            };
            experimental.plugins.fail2ban = {
              moduleName = "github.com/tomMoulard/fail2ban";
              version = "v0.8.3";
            };
            certificatesResolvers = {
              letsencrypt = {
                acme = {
                  email = config.teenix.services.traefik.letsencryptMail;
                  storage = "${config.services.traefik.dataDir}/letsencrypt.json";
                  tlsChallenge = { };
                };
              };
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

            entryPoints =
              lib.attrsets.filterAttrs (n: v: n != "port") (
                lib.attrsets.mapAttrs (
                  name: value:
                  lib.attrsets.mergeAttrsList [
                    {
                      address = ":${toString value.port}";
                    }
                    value
                    {
                      port = null;
                    }
                  ]
                ) config.teenix.services.traefik.entrypoints
              )
              // {
                udp_30001 = {
                  address = ":30001/udp";
                };
              };

            api = {
              dashboard = true;
              debug = true;
            };
          };
        };
    };
}
