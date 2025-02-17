{
  config,
  pkgs,
  pkgs-stable,
  lib,
  ...
}:
let
  t = lib.types;

  ruleType = t.attrTag {
    expr = lib.mkOption {
      description = "Raw routing rule expression for this router.";
      type = t.nonEmptyStr;
    };
    host = lib.mkOption {
      description = "Shorthand for a 'Host()' rule.";
      type = t.nonEmptyStr;
    };
  };

  mkRouterRule = rule: if rule ? "host" then "Host(`${rule.host}`)" else rule.expr;

  serviceType = t.submodule {
    options = {
      router = {
        rule = lib.mkOption {
          type = ruleType;
          description = "Define the rule for this router";
        };
        tls = {
          enable = lib.mkEnableOption {
            default = true;
            description = "Enable tls for the router";
          };
          extraConfig = lib.mkOption {
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
        extraConfig = lib.mkOption {
          type = pkgs.formats.yaml;
          default = { };
          description = "Extra settings for this router";
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
        extraConfig = lib.mkOption {
          type = pkgs.formats.yaml;
          default = { };
          description = "Extra settings for the healthcheck";
        };
      };
    };
  };
in
{
  options.teenix.services.traefik = {
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
        Traefiks' entrypoints.

        80 (web) and 443 (websecure) are added by default.
      '';
    };
    middlewares = lib.mkOption {
      type = pkgs.formats.yaml;
      default = { };
      description = "Traefiks' middlewares.";
    };
    accessLog = {
      enable = lib.mkEnableOption "enable traefik's accesslog";
      filePath = lib.mkOption {
        type = t.nonEmptyStr;
        default = "/var/log/traefik.log";
      };
    };
    services = lib.mkOption {
      type = t.attrsOf serviceType;
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

      teenix.services.traefik = {
        entrypoints = {
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

        middlewares = lib.mapAttrs' (
          name: value:
          lib.nameValuePair "redirect-${name}" {
            redirectRegex = {
              regex = "(www\\.)?${lib.replaceStrings [ "." ] [ "\." ] value.from}/?";
              replacement = value.to;
              permanent = true;
            };
          }
        ) cfg.redirects;

        services."api@internal" = {
          rule.host = cfg.dashboardUrl;
          middlewares = [ "authentik" ];
          entryPoints = [
            "web"
            "websecure"
          ];
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
          dataDir = config.nix-tun.storage.subvolumes.traefik.path;

          package = pkgs-stable.traefik;

          environmentFiles = [ config.sops.secrets.traefik_static.path ];

          dynamicConfigOptions = {
            http = {
              inherit (cfg) middlewares;

              routers = lib.mkMerge [
                # routers for services
                (lib.attrsets.mapAttrs (
                  service: serviceCfg:
                  lib.mkMerge [
                    {
                      inherit service;
                      rule = mkRouterRule serviceCfg.router.rule;
                      middlewares = serviceCfg.router.middlewares;
                      entryPoints = serviceCfg.router.entryPoints;
                      tls = lib.mkIf serviceCfg.router.tls.enable serviceCfg.router.tls.options;
                    }
                    serviceCfg.extraConfig
                  ]
                ) cfg.services)

                # redirects
                (lib.mapAttrs (name: value: {
                  service = "blank";
                  priority = 10;
                  rule = "Host(`${builtins.replaceStrings [ "." ] [ "\." ] value.from}`)";
                  middlewares = "redirect-${name}";
                  tls.certResolver = "letsencrypt";
                  entryPoints = [ "websecure" ];
                }) cfg.redirects)
              ];

              services = lib.mkMerge [
                (lib.mapAttrs (name: serviceCfg: {
                  loadBalancer = {
                    servers = map (value: {
                      url = value;
                    }) serviceCfg.servers;

                    healthCheck = lib.mkIf serviceCfg.healthCheck.enable lib.mkMerge [
                      {
                        inherit (serviceCfg.healthCheck) path interval;
                      }
                      serviceCfg.healthCheck.extraConfig
                    ];
                  };
                }) cfg.services)

                # blank services, needed for redirects
                {
                  blank = {
                    loadBalancer = {
                      servers = {
                        url = "about:blank";
                      };
                    };
                  };
                }
              ];
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
