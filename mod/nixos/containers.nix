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
            id = lib.mkOption {
              description = "network id this container should be placed in, e.g. 192.168.1";
              type = t.nullOr t.nonEmptyStr;
              default = null;
            };
            hostAddress = lib.mkOption {
              type = t.nonEmptyStr;
            };
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

            sops = {
              secrets = lib.mkOption {
                description = "sops secrets to mount into the container";
                default = [ ];
                type = t.listOf (elemTypeOf options.sops.secrets);
              };
              templates = lib.mkOption {
                description = "sops secrets/templates to mount into the container";
                default = [ ];
                type = t.listOf (elemTypeOf options.sops.templates);
              };
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
                    ownerUid = lib.mkOption {
                      description = "owner of mounted directory";
                      type = t.int;
                    };
                    mode = lib.mkOption {
                      type = t.nonEmptyStr;
                      default = "0700";
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

      defaultContainerNetworkId = "192.18";

      containerModuleOf =
        name: cfg:
        {
          config,
          pkgs,
          options,
          lib,
          ...
        }:
        {
          imports = [ cfg.config ];

          assertions = lib.singleton {
            assertion = options.system.stateVersion.highestPrio != (lib.mkOptionDefault { }).priority;
            message = "system.stateVersion is not set for container ${config.networking.hostName}. this is a terrible idea, as it can cause random breakage.";
          };

          environment.enableAllTerminfo = true;
          environment.systemPackages = lib.concatLists [
            (lib.optional cfg.mounts.postgres.enable config.services.postgresql.package)
            (lib.optional cfg.mounts.mysql.enable config.services.mysql.package)
          ];

          users.defaultUserShell = pkgs.fish;
          programs.fish = {
            enable = true;
            shellInit = ''
              function fish_greeting
                echo Entering container (set_color green)${name}
              end
            '';
          };

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
          (
            let
              networkId = lib.defaultTo "${toString defaultContainerNetworkId}.${toString (ipPoolOf containerName)}" cfg.networking.id;
            in
            {
              autoStart = true;
              ephemeral = true;
              privateNetwork = true;

              hostAddress = "${networkId}.10";
              localAddress = "${networkId}.11";

              bindMounts = lib.mkMerge [
                {
                  # resolv conf
                  resolv = lib.mkIf cfg.networking.useResolvConf {
                    hostPath = "/etc/resolv.conf";
                    mountPoint = "/etc/resolv.conf";
                  };
                  # data
                  data = lib.mkIf cfg.mounts.data.enable {
                    isReadOnly = false;
                    hostPath = "${persistPath}/${containerName}/data";
                    mountPoint = "/var/lib/${lib.defaultTo containerName cfg.mounts.data.name}";
                  };
                  # mysql
                  mysql = lib.mkIf cfg.mounts.mysql.enable {
                    isReadOnly = false;
                    hostPath = "${persistPath}/${containerName}/mysql";
                    mountPoint = config.containers.${containerName}.config.services.mysql.dataDir;
                  };
                  # postgresql
                  postgres = lib.mkIf cfg.mounts.postgres.enable {
                    isReadOnly = false;
                    hostPath = "${persistPath}/${containerName}/postgres";
                    mountPoint = config.containers.${containerName}.config.services.postgresql.dataDir;
                  };
                  # journal
                  journal = {
                    isReadOnly = false;
                    hostPath = "/var/log/containers/${containerName}";
                    mountPoint = "/var/log/journal";
                  };
                }

                # sops secrets
                (lib.listToAttrs (
                  lib.imap0 (i: v: {
                    name = toString i;
                    value = {
                      hostPath = v.path;
                      mountPoint = v.path;
                    };
                  }) cfg.mounts.sops.secrets
                ))
                # sops templates
                (lib.listToAttrs (
                  lib.imap0 (i: v: {
                    name = toString i;
                    value = {
                      hostPath = v.path;
                      mountPoint = v.path;
                    };
                  }) cfg.mounts.sops.templates
                ))

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
          )
          cfg.extraConfig
        ];
    in
    {
      assertions = [
        {
          assertion = (lib.length (lib.attrNames config.teenix.containers) < 255);
          message = "the ip pool for teenix.containers has overflown. i dont know how we ended up with this many containers, but here we are. you now need to think of a way to move some containers to a different ip range, have fun.";
        }
        {
          assertion = lib.pipe config.teenix.containers [
            (lib.filterAttrs (n: v: v.networking.id == null))
            lib.attrNames
            (lib.removeAttrs config.containers)
            lib.attrsToList
            (lib.all (
              x:
              !(lib.hasPrefix defaultContainerNetworkId x.value.hostAddress)
              && !(lib.hasPrefix defaultContainerNetworkId x.value.localAddress)
            ))
          ];
          message = "a manually specified container ip address overlaps with the reserved range for automatic address allocation. please remove it from the '${defaultContainerNetworkId}' range";
        }
      ];

      containers = lib.mapAttrs mkContainer config.teenix.containers;

      systemd.tmpfiles.rules = lib.map (containerName: ''
        d /var/log/containers/${containerName} 0755 root systemd-journal -
      '') (lib.attrNames config.teenix.containers);

      nix-tun.storage.persist.subvolumes = lib.mapAttrs (
        containerName: value:
        let
          enablePsql = value.mounts.postgres.enable;
          enableMysql = value.mounts.mysql.enable;
          enableData = value.mounts.data.enable;
          enableExtra = value.mounts.extra != { };

          containerCfg = config.containers.${containerName}.config;

          enableSubvolume = enablePsql || enableMysql || enableData || enableExtra;
        in
        lib.mkIf enableSubvolume {
          directories = lib.mkMerge [
            {
              postgres = lib.mkIf enablePsql {
                owner = toString containerCfg.users.users.postgres.uid;
                mode = "0700";
              };
              mysql = lib.mkIf enableMysql {
                owner = toString containerCfg.users.users.${containerCfg.services.mysql.user}.uid;
                mode = "0700";
              };
              data = lib.mkIf enableData {
                owner = toString value.mounts.data.ownerUid;
                mode = "0700";
              };
            }
            (lib.mapAttrs (_: v: {
              inherit (v) mode;
              owner = toString v.ownerUid;
            }) value.mounts.extra)
          ];
        }
      ) config.teenix.containers;
    };
}
