{
  lib,
  config,
  options,
  specialArgs,
  ...
}@host:
{
  options.teenix.containers =
    let
      t = lib.types;

      containerType = t.submodule (
        { name, ... }:
        {
          options = {
            config = lib.mkOption {
              description = "The container's NixOS configuration";
              type = t.deferredModule;
            };

            machineId = lib.mkOption {
              description = "The containers machine-id. Used for mounting journals";
              type = t.strMatching "^[a-f0-9]{32}\n$";
              default = "${lib.substring 0 32 (builtins.hashString "sha256" name)}\n";
              defaultText = "derived from the containers name, first 32 digits of the name's sha256 hash";
            };

            privateUsers = lib.mkOption {
              description = ''
                Whether to give the container its own private UIDs/GIDs space (user namespacing).
                This greatly enhances security.

                In addition to the options provided by nixos containers, this option also takes a boolean.
                If true, privateUsers is set to "pick", If set to false, privateUsers is set to "no"
              '';
              type = t.either t.bool (
                t.either t.ints.u32 (
                  t.enum [
                    "no"
                    "identity"
                    "pick"
                  ]
                )
              );
              default = false;
            };

            networking = {
              useResolvConf = lib.mkEnableOption ''
                Mount the hosts resolv.conf into the container.

                This is required if the container wants to do dns lookups.
              '';
              id = lib.mkOption {
                description = "Network id this container should be placed in, e.g. 192.168.1";
                type = t.nullOr t.nonEmptyStr;
                default = null;
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

            backup = lib.mkEnableOption null // {
              default = true;
              example = false;
              description = "Backup this containers persisted subvolume";
            };

            mounts = {
              mysql.enable = lib.mkEnableOption null // {
                description = "Mount the container's mysql data dir into persisted storage";
              };

              postgres.enable = lib.mkEnableOption null // {
                description = "Mount the container's postgesql data dir into persisted storage";
              };

              data = {
                enable = lib.mkEnableOption null // {
                  description = "Mount /var/lib/<containerName> into persisted storage";
                };

                ownerUid = lib.mkOption {
                  description = "Owner of the data dir";
                  type = t.nullOr t.int;
                  default = null;
                };
                name = lib.mkOption {
                  description = "Change the folder name under /var/lib";
                  type = t.nonEmptyStr;
                  default = name;
                };
              };

              sops = {
                secrets = lib.mkOption {
                  description = "Sops secrets to mount into the container";
                  visible = "shallow";
                  default = [ ];
                  type = t.listOf (lib.teenix.elemTypeOf options.sops.secrets);
                };
                templates = lib.mkOption {
                  description = "Sops templates to mount into the container";
                  visible = "shallow";
                  default = [ ];
                  type = t.listOf (lib.teenix.elemTypeOf options.sops.templates);
                };
              };

              extra = lib.mkOption {
                default = { };
                description = "Additional Mounts for the container";
                type = t.attrsOf (
                  t.submodule {
                    options = {
                      mountPoint = lib.mkOption {
                        description = "Path inside the container to mount to";
                        type = t.nonEmptyStr;
                      };
                      hostPath = lib.mkOption {
                        description = "Path on the host to mount from";
                        type = t.nullOr t.nonEmptyStr;
                        default = null;
                      };
                      isReadOnly = lib.mkOption {
                        description = "Mount read-only";
                        type = t.bool;
                        default = true;
                      };
                      ownerUid = lib.mkOption {
                        description = "Owner's UID of the Mounted Directory";
                        type = t.nullOr t.int;
                        default = null;
                      };
                      mode = lib.mkOption {
                        description = "Mode of the Mounted Directory";
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
        }
      );
    in
    lib.mkOption {
      type = t.attrsOf containerType;
      description = "";
      default = { };
    };

  config =
    let
      defaultContainerNetworkId = "192.18";

      # ugly hack to generate a unique ip for the container
      ipPoolOf =
        name:
        lib.lists.findFirstIndex (x: x == name) (throw "unreachable") (lib.attrNames config.containers);

      containerModuleOf =
        name: cfg:
        {
          config,
          host-config,
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

          environment = {
            enableAllTerminfo = true;
            systemPackages = lib.concatLists [
              (lib.optional cfg.mounts.postgres.enable config.services.postgresql.package)
              (lib.optional cfg.mounts.mysql.enable config.services.mysql.package)
            ];
            shellAliases = rec {
              ls = "${lib.getExe pkgs.eza} -F --sort extension --group-directories-first --git --icons -Mo --hyperlink --git-repos-no-status --color-scale=size --no-permissions ";
              ll = ls + "-l ";
              la = ll + "-a ";
              l = ll;
              gls = ll + "--git-ignore ";
            };
          };

          services.journald.extraConfig = "MaxFileSec=1 month";

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

          networking = {
            hostId = lib.substring 0 8 cfg.machineId;
            useHostResolvConf = false;
            firewall = {
              enable = true;
              allowedTCPPorts = cfg.networking.ports.tcp;
              allowedUDPPorts = cfg.networking.ports.tcp;
            };
            hosts = {
              "${host-config.containers.${name}.hostAddress}" = [ host-config.networking.hostName ];
            };
          };

          services.resolved.enable = true;
        };

      sopsToMounts =
        typeName: objs:
        lib.listToAttrs (
          lib.imap0 (i: v: {
            name = "${typeName}-${toString i}";
            value = {
              hostPath = v.path;
              mountPoint = v.path;
            };
          }) objs
        );

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

              # if private users is a bool map it to "pick" or "no", else just pass thru
              privateUsers =
                if cfg.privateUsers == true then
                  "pick"
                else if cfg.privateUsers == false then
                  "no"
                else
                  cfg.privateUsers;

              hostAddress = "${networkId}.10";
              localAddress = "${networkId}.11";

              extraFlags = lib.concatLists [
                (lib.singleton "--uuid=${cfg.machineId}")
                (lib.optional cfg.networking.useResolvConf "--resolv-conf=bind-host")
              ];

              bindMounts = lib.mkMerge [
                {
                  # data
                  data = lib.mkIf cfg.mounts.data.enable {
                    isReadOnly = false;
                    hostPath = "${config.teenix.persist.subvolumes.${containerName}.path}/data";
                    mountPoint = "/var/lib/${cfg.mounts.data.name}";
                  };
                  # mysql
                  mysql = lib.mkIf cfg.mounts.mysql.enable {
                    isReadOnly = false;
                    hostPath = "${config.teenix.persist.subvolumes.${containerName}.path}/mysql";
                    mountPoint = config.containers.${containerName}.config.services.mysql.dataDir;
                  };
                  # postgresql
                  postgres = lib.mkIf cfg.mounts.postgres.enable {
                    isReadOnly = false;
                    hostPath = "${config.teenix.persist.subvolumes.${containerName}.path}/postgres";
                    mountPoint = config.containers.${containerName}.config.services.postgresql.dataDir;
                  };
                  # journal
                  journal = {
                    isReadOnly = false;
                    hostPath = "/var/log/containers/${containerName}";
                    mountPoint = "/var/log/journal/${cfg.machineId}";
                  };
                }

                # sops secrets
                (sopsToMounts "sops-secret" cfg.mounts.sops.secrets)
                (sopsToMounts "sops-template" cfg.mounts.sops.templates)

                # extra mounts
                (lib.mapAttrs (n: value: {
                  inherit (value) mountPoint isReadOnly;
                  hostPath = lib.defaultTo "${config.teenix.persist.subvolumes.${containerName}.path}/${n}" value.hostPath;
                }) cfg.mounts.extra)
              ];

              config = containerModuleOf containerName cfg;
              specialArgs = specialArgs // {
                host-config = host.config;
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

      teenix.persist.subvolumes = lib.mapAttrs (
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
          inherit (value) backup;
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
                inherit (value.mounts.data) owner;
                mode = "0700";
              };
            }
            (lib.mapAttrs (_: v: {
              inherit (v) mode owner;
            }) (lib.filterAttrs (_: v: v.hostPath != null) value.mounts.extra))
          ];
        }
      ) config.teenix.containers;
    };
}
