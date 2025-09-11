{
  pkgs,
  pkgs-stable,
  config,
  lib,
  ...
}:
let
  cfg = config.teenix.services.traefik;
  t = lib.types;

  yaml = pkgs.formats.yaml { };

  entryPointType = t.submodule {
    options = {
      port = lib.mkOption {
        description = "port of this entrypoint";
        type = t.port;
      };
      protocol = lib.mkOption {
        description = "protocol of this entrypoint";
        default = "tcp";
        type = lib.types.enum [
          "tcp"
          "udp"
        ];
      };
      extraConfig = lib.mkOption {
        description = "extra config options for this entrypoint";
        type = yaml.type;
        default = { };
      };
    };
  };

  httpServiceType = t.submodule {
    options = {
      router = {
        rule = lib.mkOption {
          description = "rule for this router, see https://doc.traefik.io/traefik/routing/routers/#configuring-http-routers";
          type = t.nonEmptyStr;
        };

        tls = {
          enable = lib.mkEnableOption "tls for this router" // {
            default = true;
          };
          certResolver = lib.mkOption {
            description = "certificate resolver for this router";
            type = t.nonEmptyStr;
            default = "letsencrypt";
          };
        };

        entryPoints = lib.mkOption {
          description = ''
            entryPoints for this router

            if tls is enabled, uses websecure (https) by default;
          '';
          default = [ ];
          type = t.listOf (t.nonEmptyStr);
        };

        middlewares = lib.mkOption {
          description = "list of middlewares for this router";
          type = t.listOf t.nonEmptyStr;
          default = [ ];
        };

        extraConfig = lib.mkOption {
          description = "extra config options for this router";
          type = yaml.type;
          default = { };
        };
      };

      servers = lib.mkOption {
        description = "hosts for this service";
        type = t.listOf t.nonEmptyStr;
        default = [ ];
      };

      healthCheck = {
        enable = lib.mkEnableOption "health checking for this service";
        path = lib.mkOption {
          description = "path to healthcheck on";
          type = t.str;
          default = "/";
        };
        interval = lib.mkOption {
          description = "interval between health checks";
          type = t.nonEmptyStr;
          default = "10s";
        };
      };

      extraConfig = lib.mkOption {
        description = "extra config options for this services, as defined in the dynamic config";
        type = yaml.type;
        default = { };
      };
    };
  };

  redirectType = lib.types.submodule {
    options = {
      from = lib.mkOption {
        description = "url to redirect from";
        type = lib.types.str;
      };
      to = lib.mkOption {
        description = "url to redirect to";
        type = lib.types.str;
      };
    };
  };

  phynixIpAllowList = [
    "134.99.147.40/27" # phynix subnet
    "192.18.0.0/16" # auto generated nixos containers
    "192.168.0.0/16" # manual container ips
  ];

  hhudyIpAllowList = [
    "134.99.147.40" # hhudy
    "134.99.147.41" # verleihnix
    "134.99.147.42" # teefax
    "134.99.147.43" # sebigbos
    "192.18.0.0/16" # auto generated nixos containers
    "192.168.0.0/16" # manual container ips
  ];
in
{
  # we pretty much reimplement the entires traefik module.
  # using it is so absolutely definitely a bug, that we completely disable the nixpkgs one.
  disabledModules = [
    "services/web-servers/traefik.nix"
  ];

  imports = [ ./meta.nix ];

  options.teenix.services.traefik = {
    enable = lib.mkEnableOption "traefik";
    secretsFile = lib.teenix.mkSecretsFileOption "traefik";

    letsencryptMail = lib.mkOption {
      description = "The email address used for letsencrypt certificates";
      type = t.nonEmptyStr;
    };

    dashboard = {
      enable = lib.mkEnableOption null // {
        description = ''
          Whether so serve the traefik dashboard. 

          It will only be accessible from within the PhyNIx HHU Subnet
        '';
      };

      url = lib.mkOption {
        description = "url to serve the dashboard on";
        type = t.nonEmptyStr;
      };
    };

    redirects = lib.mkOption {
      type = lib.types.attrsOf redirectType;
      description = "Redirect one URL to another";
      example = {
        fscs_phynix = {
          from = "fscs.phynix-hhu.de";
          to = "fscs.hhu.de";
        };
      };
      default = { };
    };


    entryPoints = lib.mkOption {
      description = "Traefik's entrypoints, as defined in the static config";
      type = t.attrsOf entryPointType;
      default = { };
    };
    
    httpMiddlewares = lib.mkOption {
      description = "Traefik's middlewares, as defined in the dynamic config";
      type = yaml.type;
      default = { };
    };

    httpServices = lib.mkOption {
      description = "http based services, each using a single per-service router";
      type = t.attrsOf httpServiceType;
      default = { };
    };

    tcpMiddlewares = lib.mkOption {
      description = "Traefik's middlewares, as defined in the dynamic config";
      type = yaml.type;
      default = { };
    };

    dynamicConfig = lib.mkOption {
      description = ''
        Traefik's dynamic config options.

        This is passed through sops-nix templating, so you can use 
        sops.placeholders to insert secrets into the config
      '';
      type = yaml.type;
      default = { };
    };

    staticConfig = lib.mkOption {
      description = ''
        Traefik's static config options.

        This is passed through sops-nix templating, so you can use 
        sops.placeholders to insert secrets into the config
      '';
      type = yaml.type;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    # TODO: check for non-existent entrypoints
    # TODO: warn if services dont have entrypoints (tls is disabled and none specified)

    teenix.services.traefik.entryPoints = {
      web = {
        port = 80;
        extraConfig.http = {
          redirections.entryPoint = {
            to = "websecure";
            scheme = "https";
          };
        };
      };
      websecure = {
        port = 443;
      };
      metrics = {
        port = 120;
      };
    };

    teenix.services.traefik.httpMiddlewares = {
      hsts.headers = {
        STSSeconds = 31536000;
        STSPreload = true;
        STSIncludeSubdomains = true;
      };
      onlyphynix.ipAllowList.sourceRange = phynixIpAllowList;
      onlyhhudy.ipAllowList.sourceRange = hhudyIpAllowList;
    };

    teenix.services.traefik.tcpMiddlewares = {
      onlyphynix.ipAllowList.sourceRange = phynixIpAllowList;
      onlyhhudy.ipAllowList.sourceRange = hhudyIpAllowList;
    };

    # generate traefiks dynamic config
    teenix.services.traefik.dynamicConfig = {
      http = {
        routers = lib.mkMerge [
          # generate routers for http services
          (lib.mapAttrs (
            service: serviceCfg:
            lib.mkMerge [
              # inherit options that we can unconditionally pass through
              {
                inherit service;
                inherit (serviceCfg.router)
                  rule
                  entryPoints
                  middlewares
                  ;
              }

              # if tls is desired, set some defaults
              (lib.mkIf serviceCfg.router.tls.enable {
                tls.certResolver = serviceCfg.router.tls.certResolver;
                entryPoints = [ "websecure" ];
                middlewares = [ "hsts" ];
              })

              # merge extra overrides
              serviceCfg.router.extraConfig
            ]
          ) cfg.httpServices)

          # generate routers for our redirects
          (lib.attrsets.mapAttrs (name: value: {
            service = "blank";
            priority = 10;
            rule = "Host(`${builtins.replaceStrings [ "." ] [ "\." ] value.from}`)";
            middlewares = name;
            tls.certResolver = "letsencrypt";
            entryPoints = [ "websecure" ];
          }) cfg.redirects)

          # dashboard router
          (lib.mkIf cfg.dashboard.enable {
            dashboard = {
              rule = "Host(`${cfg.dashboard.url}`)";
              service = "api@internal";
              entryPoints = [
                "web"
                "websecure"
              ];
              middlewares = [ "authentik" ];
              tls.certResolver = "letsencrypt";
            };
          })
        ];

        middlewares = lib.mkMerge [
          # generate redirect middlewares
          (lib.attrsets.mapAttrs (name: value: {
            redirectRegex = {
              regex = "(www\\.)?${builtins.replaceStrings [ "." ] [ "\." ] value.from}/?";
              replacement = value.to;
              # dont do permanent redirects. if they ever change its a disaster and
              # the performance overhead is neglible
            };
          }) cfg.redirects)

          # other middlewares
          cfg.httpMiddlewares
        ];

        services = lib.mkMerge [
          # generate http services
          (lib.attrsets.mapAttrs (
            _: serviceCfg:
            lib.mkMerge [
              {
                loadBalancer = {
                  servers = map (value: { url = value; }) serviceCfg.servers;
                  healthCheck = lib.mkIf serviceCfg.healthCheck.enable {
                    inherit (serviceCfg.healthCheck) path interval;
                  };
                };
              }
              serviceCfg.extraConfig
            ]
          ) cfg.httpServices)

          # the blank service is needed for redirects
          {
            blank = {
              loadBalancer.servers.url = "about:blank";
            };
          }
        ];
      };

      tcp = {
        middlewares = cfg.tcpMiddlewares;
      };
    };

    # generate traefiks static config
    teenix.services.traefik.staticConfig = {
      # enable traefiks metrics, so prometheus can read them
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

      providers = {
        file = {
          filename = config.sops.templates.traefik-dynamic-config.path;
          watch = false;
        };
        docker = lib.mkIf config.virtualisation.docker.enable {
          exposedByDefault = false;
          watch = true;
        };
      };

      certificatesResolvers.letsencrypt = {
        acme = {
          email = cfg.letsencryptMail;
          storage = "${config.teenix.persist.subvolumes.traefik.path}/letsencrypt.json";
          tlsChallenge = { };
        };
      };

      entryPoints = lib.mapAttrs (
        n: v:
        lib.mkMerge [
          { address = ":${toString v.port}/${v.protocol}"; }
          v.extraConfig
        ]
      ) cfg.entryPoints;

      api.dashboard = cfg.dashboard.enable;
    };

    users.users.traefik.extraGroups = lib.mkIf config.virtualisation.docker.enable [ "docker" ];

    # automatically open firewall ports for all entrypoints
    networking.firewall = {
      allowedTCPPorts = lib.mapAttrsToList (_: v: v.port) (
        lib.filterAttrs (_: v: v.protocol == "tcp") cfg.entryPoints
      );

      allowedUDPPorts = lib.mapAttrsToList (_: v: v.port) (
        lib.filterAttrs (_: v: v.protocol == "udp") cfg.entryPoints
      );
    };

    # sops templates for static and dynamic config, so secrets can be used in the config
    sops.templates = {
      traefik-dynamic-config = {
        name = "traefik-dynamic-config.yml";
        owner = config.users.users.traefik.name;
        file = yaml.generate "traefik-dynamic-config.yml" cfg.dynamicConfig;
        reloadUnits = [ "traefik.service" ];
      };

      traefik-static-config = {
        name = "traefik-static-config.yml";
        owner = config.users.users.traefik.name;
        file = yaml.generate "traefik-static-config.yml" cfg.staticConfig;
        restartUnits = [ "traefik.service" ];
      };
    };

    # subvolume to persist traefiks data dir
    teenix.persist.subvolumes.traefik = {
      owner = "traefik";
      group = "traefik";
      mode = "700";
    };

    # we pretty much inline the whole non-option part of the nixos traefik module here
    # because it sets up a systemd tmpfile rule to create its data dir.
    # this interferes with out tmpfile rule, because we want to create it as
    # a subvolume
    #
    # we also implement service reloading
    systemd.services.traefik = {
      description = "Traefik reverse proxy";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      startLimitIntervalSec = 86400;
      startLimitBurst = 5;
      serviceConfig = {
        ExecStart = "${lib.getExe pkgs-stable.traefik} --configfile=${config.sops.templates.traefik-static-config.path}";
        ExecReload = "${lib.getExe' pkgs.util-linux "kill"} -HUP $MAINPID";
        Type = "notify";
        WatchdogSec = "10s";
        User = "traefik";
        Group = "traefik";
        Restart = "on-failure";
        AmbientCapabilities = "cap_net_bind_service";
        CapabilityBoundingSet = "cap_net_bind_service";
        NoNewPrivileges = true;
        LimitNPROC = 64;
        LimitNOFILE = 1048576;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectHome = true;
        ProtectSystem = "full";
        ReadWritePaths = [ config.teenix.persist.subvolumes.traefik.path ];
      };
      
      unitConfig.AssertPathExists = [
        config.sops.templates.traefik-static-config.path
        config.sops.templates.traefik-dynamic-config.path
      ];
    };

    users.groups.traefik = { };
    users.users.traefik = {
      group = "traefik";
      home = config.teenix.persist.subvolumes.traefik.path;
      isSystemUser = true;
    };
  };
}
