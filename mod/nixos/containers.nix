{ lib
, inputs
, outputs
, pkgs-master
, config
, ...
}:
{
  options.teenix.containers =
    let
      t = lib.types;

      dbMountType = {
        enable = lib.mkEnableOption "mount the dbs data dir";
        path = lib.mkOption {
          description = "location of the data dir within the container";
          type = t.nullOr t.nonEmptyStr;
          default = null;
        };
      };

      containerType = t.submodule {
        options = {
          config = lib.mkOption {
            description = "container configuration file";
            type = t.deferredModule;
          };

          networking.ports = {
            tcp = lib.mkOption {
              type = t.listOf t.port;
              default = [ ];
            };
            udp = lib.mkOption {
              type = t.listOf t.port;
              default = [ ];
            };
          };

          useResolvConf = lib.mkEnableOption "mount resolv.conf into the container";

          mounts = {
            mysql = dbMountType;
            postgresql = dbMountType;

            logs = {
              enable = lib.mkEnableOption "mount logs";
              paths = lib.mkOption {
                description = "directory names in /var/log to mount to the log dir";
                type = t.listOf t.str;
                default = [ ];
              };
            };

            sops = lib.mkOption {
              description = "sops secrets/templates to mount into the container";
              default = [ ];
              type = t.listOf (
                t.submodule {
                  path = t.mkOption {
                    type = t.str;
                  };
                }
              );
            };

            extra = lib.mkOption {
              default = { };
              type = t.attrsOf (
                t.submodule {
                  options = {
                    mountPoint = lib.mkOption {
                      type = t.nonEmptyStr;
                    };
                    isReadOnly = lib.mkOption {
                      type = t.bool;
                      default = true;
                    };
                  };
                }
              );
            };
          };

          extraConfig = lib.mkOption {
            description = "extra options/overrides to pass to the container";
            type = t.attrs;
            default = { };
          };
        };
      };
    in
    lib.mkOption {
      type = t.attrsOf containerType;
      default = { };
    };

  config =
    let
      persistPath = config.nix-tun.storage.persist.path;

      containerModuleOf =
        name: cfg:
        { ... }:
        {
          imports = [ cfg.config ];

          nix.settings.experimental-features = "nix-command flakes";

          networking.hostName = name;
          networking.useHostResolvConf = lib.mkForce false;
          networking.firewall = {
            enable = true;
            allowedTCPPorts = cfg.networking.ports.tcp;
            allowedUDPPorts = cfg.networking.ports.tcp;
          };

          services.resolved.enable = true;
        };

      # ugly hack to generate a unique ip for the container
      ipPoolOf =
        name:
        lib.lists.findFirstIndex (x: x == name) (throw "unreachable") (lib.attrNames config.containers);

      mkContainer =
        containerName: cfg:
        lib.recursiveUpdate
          {
            autoStart = true;
            ephemeral = true;
            privateNetwork = true;

            hostAddress = "192.18.${toString (ipPoolOf containerName)}.10";
            localAddress = "192.18.${toString (ipPoolOf containerName)}.11";

            bindMounts = lib.mkMerge [
              # resolv conf
              (lib.mkIf cfg.useResolvConf {
                resolv = {
                  hostPath = "/etc/resolv.conf";
                  mountPoint = "/etc/resolv.conf";
                };
              })
              # sops mounts
              (lib.listToAttrs (
                lib.imap0
                  (i: v: {
                    name = toString i;
                    value = {
                      hostPath = v.path;
                      mountPoint = v.path;
                    };
                  })
                  cfg.mounts.sops
              ))
              # mysql
              (lib.mkIf cfg.mounts.mysql.enable {
                mysql = {
                  hostPath = "${persistPath}/${containerName}/mysql";
                  mountPoint =
                    lib.defaultTo config.containers.${containerName}.config.services.mysql.dataDir
                      cfg.mounts.mysql.path;
                };
              })
              # postgresql
              (lib.mkIf cfg.mounts.postgresql.enable {
                postgresql = {
                  hostPath = "${persistPath}/${containerName}/postgresql";
                  mountPoint =
                    lib.defaultTo config.containers.${containerName}.config.services.postgresql.dataDir
                      cfg.mounts.postgresql.path;
                };
              })
              # logs
              (lib.genAttrs cfg.mounts.logs.paths (n: {
                hostPath = "/var/log/containers/${containerName}/${n}";
                mountPoint = "/var/log/${n}";
                isReadOnly = false;
              }))
              # extra mounts
              (lib.traceValSeq (lib.mapAttrs
                (n: value: {
                  inherit (value) mountPoint isReadOnly;
                  hostPath = "${persistPath}/${containerName}/${n}";
                })
                cfg.mounts.extra))
            ];

            config = containerModuleOf containerName cfg;
            specialArgs = {
              inherit inputs outputs pkgs-master;
              host-config = config;
            };
          }
          cfg.extraConfig;
    in
    {
      containers = lib.mapAttrs mkContainer config.teenix.containers;
    };
}
