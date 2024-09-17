{ config
, pkgs
, lib
, ...
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
    redirects =
      let
        redirectOpts = lib.types.submodule
          {
            options = {
              from = lib.mkOption {
                type = lib.types.str;
                default = "";
                description = ''
                '';
              };
              to = lib.mkOption {
                type = lib.types.str;
                default = "";
                description = ''
                '';
              };
            };
          };
      in
      lib.mkOption
        {
          type = lib.types.attrsOf redirectOpts;
          default = { };
          description = ''
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
    services =
      let
        serviceOpts = lib.types.submodule {
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
                default = [ ];
                description = ''
                  The middlewares applied to the router, the middlewares are applied in order.
                '';
              };
              entryPoints = lib.mkOption {
                type = lib.types.listOf (lib.types.str);
                default = [ "websecure" ];
                description = ''
                  The Entrypoint of the service, default is 443 (websecure)
                '';
              };
            };
            servers = lib.mkOption {
              type = lib.types.listOf (lib.types.str);
              default = [ ];
              description = ''
                The hosts of the service
              '';
            };
            healthCheck = {
              enable = lib.mkEnableOption {
                default = false;
                description = ''
                  Enable the HealthCheck for this serviceOpts
                '';
              };
              path = lib.mkOption {
                type = lib.types.str;
                default = "/";
                description = ''
                  set the Healthcheck Path
                '';
              };
              interval = lib.mkOption {
                type = lib.types.str;
                default = "10s";
                description = ''
                  set the Healthcheck Interval
                '';
              };
            };
          };
        };
      in
      lib.mkOption {
        type = lib.types.attrsOf serviceOpts;
        default = { };
        description = ''
          A simple setup to configure http loadBalancer services and routers.
        '';
      };
  };

  config = lib.mkIf config.teenix.services.traefik.enable
    {
      users.users.traefik.extraGroups = [ "docker" ];
      networking.firewall.allowedTCPPorts = lib.attrsets.mapAttrsToList (name: value: value.port) config.teenix.services.traefik.entrypoints;

      services.traefik =
        let

          dynamicConfig = pkgs.runCommand "config.toml"
            {
              buildInputs = [ pkgs.remarshal ];
              preferLocalBuild = true;
            } ''
            remarshal -if json -of toml \
              < ${
                pkgs.writeText "dynamic_config.json"
                (builtins.toJSON  config.services.traefik.dynamicConfigOptions)
              } \
              > $out
          '';

          configDir = pkgs.stdenv.mkDerivation {
            name = "traefikConfig";
            src = ./.;
            buildPhase = ''
              mkdir $out
              ln -s ${dynamicConfig} $out/dyn_config.toml
              ln -s ${config.sops.secrets.traefik.path} $out/dyn_sops.toml
            '';
          };
        in
        {
          package = pkgs.unstable.traefik;
          enable = true;

          dynamicConfigOptions =
            {
              tls.certificates = [{
                certFile = "/persist/traefik/certificates/fscs.hhu.de.crt";
                keyFile = "/persist/traefik/certificates/fscs.hhu.de.key";
              }];
              http =
                {
                  routers =
                    (
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
                        config.teenix.services.traefik.services)
                    //
                    lib.attrsets.mapAttrs
                      (
                        name: value:
                          {
                            service = "blank";
                            priority = 10;
                            rule = "Host(`${value.from}`)";
                            middlewares = name;
                            tls.certResolver = "letsencrypt";
                          }
                      )
                      config.teenix.services.traefik.redirects
                    //
                    {
                      dashboard = {
                        rule = "Host(`${config.teenix.services.traefik.dashboardUrl}`)";
                        service = "api@internal";
                        entryPoints = [ "websecure" ];
                        tls.certResolver = "letsencrypt";
                      };
                    };
                  middlewares =
                    lib.attrsets.mapAttrs
                      (
                        name: value:
                          {
                            redirectRegex = {
                              regex = "(www\\.)?${builtins.replaceStrings ["." "/"] ["\\." "\\/"] value.from}/?";
                              replacement = value.to;
                              permanent = true;
                            };
                          }
                      )
                      config.teenix.services.traefik.redirects
                    //
                    {
                      meteredirect.redirectregex = {
                        regex = "https://mete.hhu-fscs.de/(.*?)((/deposit)|(/retrieve)|(/transaction))(.*)";
                        replacement = "https://mete.hhu-fscs.de/$1";
                      };
                      authentik.forwardAuth = {
                        address = "https://authentik:9443/outpost.goauthentik.io/auth/traefik";
                        trustForwardHeader = true;
                        tls.insecureSkipVerify = true;
                        authResponseHeaders = [ "X-authentik-username" "X-authentik-groups" "X-authentik-email" "X-authentik-name" "X-authentik-uid" "X-authentik-jwt" "X-authentik-meta-jwks" "X-authentik-meta-outpost" "X-authentik-meta-provider" "X-authentik-meta-app" "X-authentik-meta-version" ];
                      };
                    };
                  services =
                    lib.attrsets.mapAttrs
                      (name: value:
                        {
                          loadBalancer =
                            lib.mkMerge [
                              {
                                servers = builtins.map
                                  (value: {
                                    url = value;
                                  })
                                  value.servers;
                              }
                              (lib.mkIf value.healthCheck.enable {
                                healthCheck = {
                                  path = value.healthCheck.path;
                                  interval = value.healthCheck.interval;
                                };
                              })
                            ];
                        }
                      )
                      config.teenix.services.traefik.services
                    //
                    {
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
          staticConfigOptions =
            {
              metrics.prometheus = {
                entryPoint = "metrics";
                buckets = [ 0.1 0.3 1.2 5.0 ];
                addEntryPointsLabels = true;
                addServicesLabels = true;
              };
              providers.file.directory = configDir;
              providers.docker = {
                exposedByDefault = false;
                watch = true;
              };
              ping = {
                entryPoint = "ping";
              };
              certificatesResolvers = {
                letsencrypt = {
                  acme = {
                    email = config.teenix.services.traefik.letsencryptMail;
                    storage = "/var/lib/traefik/acme.json";
                    tlsChallenge = { };
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

      system.stateVersion = "23.11";
    };
}
