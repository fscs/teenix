{
  lib,
  config,
  options,
  specialArgs,
  ...
}:
{
  options.teenix.containers =
    let
      t = lib.types;

      elemTypeOf = o: o.type.nestedTypes.elemType;

      containerType = t.submodule {
        options = {
          config = lib.mkOption {
            description = "The container's NixOS configuration";
            type = t.deferredModule;
          };

          networking = {
            useResolvConf = lib.mkEnableOption ''
              Mount the hosts resolv.conf into the container.

              This is required if the container wants to do dns lookups.
            '';
            ports = {
              tcp = lib.mkOption {
                description = "TCP Ports to open in the containers firewall";
                type = t.listOf t.port;
                default = [ ];
              };
              udp = lib.mkOption {
                type = t.listOf t.port;
                description = "UDP Ports to open in the containers firewall";
                default = [ ];
              };
            };
          };

          mounts = {
            mysql.enable = lib.mkEnableOption "Mount the container's mysql data dir into the hosts /persist";
            postgres.enable = lib.mkEnableOption "Mount the container's postgresql data dir into the hosts /persist";

            data = {
              enable = lib.mkEnableOption "mount /var/lib/<containerName>";
              ownerUid = lib.mkOption {
                description = "owner of the data dir";
                type = t.int;
              };
              name = lib.mkOption {
                description = "change the folder name under /var/lib";
                type = t.nullOr t.nonEmptyStr;
                default = null;
              };
            };

            logs.paths = lib.mkOption {
              description = "directory names in /var/log to mount to the log dir";
              type = t.listOf t.str;
              default = [ ];
            };

            sops = lib.mkOption {
              description = "sops secrets/templates to mount into the container";
              default = [ ];
              type = t.listOf (t.either (elemTypeOf options.sops.templates) (elemTypeOf options.sops.secrets));
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
        { config, options, lib, ... }:
        {
          imports = [ cfg.config ];

          assertions = lib.singleton {
            assertion = options.system.stateVersion.highestPrio != (lib.mkOptionDefault { }).priority;
            message = "system.stateVersion is not set for container ${config.networking.hostName}. this is a terrible idea, as it can cause random breakage.";
          };

          environment.systemPackages = lib.concatLists [
            (lib.optional cfg.mounts.postgres.enable config.services.postgresql.package)
            (lib.optional cfg.mounts.mysql.enable config.services.mysql.package)
          ];

          nix.settings.experimental-features = "nix-command flakes";

          networking.useHostResolvConf = false;
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
        lib.mkMerge [
          {
            autoStart = true;
            ephemeral = true;
            privateNetwork = true;

            hostAddress = "192.18.${toString (ipPoolOf containerName)}.10";
            localAddress = "192.18.${toString (ipPoolOf containerName)}.11";

            bindMounts = lib.mkMerge [
              # resolv conf
              (lib.mkIf cfg.networking.useResolvConf {
                resolv = {
                  hostPath = "/etc/resolv.conf";
                  mountPoint = "/etc/resolv.conf";
                };
              })
              # sops mounts
              (lib.listToAttrs (
                lib.imap0 (i: v: {
                  name = toString i;
                  value = {
                    hostPath = v.path;
                    mountPoint = v.path;
                  };
                }) cfg.mounts.sops
              ))
              # data
              (lib.mkIf cfg.mounts.data.enable {
                data = {
                  isReadOnly = false;
                  hostPath = "${persistPath}/${containerName}/data";
                  mountPoint = "/var/lib/${lib.defaultTo containerName cfg.mounts.data.name}";
                };
              })
              # mysql
              (lib.mkIf cfg.mounts.mysql.enable {
                mysql = {
                  isReadOnly = false;
                  hostPath = "${persistPath}/${containerName}/mysql";
                  mountPoint = config.containers.${containerName}.config.services.mysql.dataDir;
                };
              })
              # postgresql
              (lib.mkIf cfg.mounts.postgres.enable {
                postgres = {
                  isReadOnly = false;
                  hostPath = "${persistPath}/${containerName}/postgres";
                  mountPoint = config.containers.${containerName}.config.services.postgresql.dataDir;
                };
              })
              # logs
              (lib.genAttrs cfg.mounts.logs.paths (n: {
                hostPath = "/var/log/containers/${containerName}/${n}";
                mountPoint = "/var/log/${n}";
                isReadOnly = false;
              }))
              # extra mounts
              (lib.mapAttrs (n: value: {
                inherit (value) mountPoint isReadOnly;
                hostPath = "${persistPath}/${containerName}/${n}";
              }) cfg.mounts.extra)
            ];

            config = containerModuleOf containerName cfg;
            specialArgs = specialArgs // {
              host-config = config;
            };
          }
          cfg.extraConfig
        ];
    in
    {
      containers = lib.mapAttrs mkContainer config.teenix.containers;

      systemd.tmpfiles.rules =
        # map over each container
        lib.flatten (
          lib.mapAttrsToList (
            n: v:
            # map over the mounted logs
            lib.map (l: ''
              d /var/log/containers/${n}/${l} 0755 root users -
            '') v.mounts.logs.paths
          ) config.teenix.containers
        );

      nix-tun.storage.persist.subvolumes = lib.mapAttrs (
        name: value:
        let
          enablePsql = value.mounts.postgres.enable;
          enableMysql = value.mounts.mysql.enable;
          enableData = value.mounts.data.enable;

          containerCfg = config.containers.${name}.config;

          enableSubvolume = enablePsql || enableMysql || enableData;
        in
        lib.mkIf enableSubvolume {
          directories = {
            postgres = lib.mkIf enablePsql {
              owner = toString containerCfg.users.users.postgres.uid;
              mode = "0700";
            };
            mysql = lib.mkIf enableMysql {
              owner = toString containerCfg.users.users.${containerCfg.services.mysql.user}.uid;
              mode = "0700";
            };
            data = lib.mkIf value.mounts.data.enable {
              owner = toString value.mounts.data.ownerUid;
              mode = "0700";
            };
          };
        }
      ) config.teenix.containers;
    };
}
