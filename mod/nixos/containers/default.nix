{
  lib,
  config,
  specialArgs,
  ...
}@host:
{
  imports = [ ./meta.nix ];

  options.teenix.config = {
    defaultContainerNetworkId = lib.mkOption {
      description = "The default network id for containers. This is used to generate the container ip address";
      type = lib.types.nonEmptyStr;
      example = "192.18";
    };
  };
  options.teenix.containers =
    let
      t = lib.types;

      containerType = t.submodule (
        { name, ... }:
        {
          options = {
            config = lib.mkOption {
              description = ''
                The containers NixOS configuration, specified as a file, attribute set or NixOS Module function.

                The special arg "host-config" can be used to access the hosts configuration from within the container.
              '';
              example = {
                services.postgresql.enable = true;

                system.stateVersion = "24.11";
              };
              type = t.deferredModule;
            };

            machineId = lib.mkOption {
              description = ''
                The containers machine-id, uniquely identifiying this container.
                You shouldn't ever have to set this yourself.

                Used for mounting the systemd journals back to the host.
              '';
              type = t.strMatching "^[a-f0-9]{32}\n$";
              default = lib.substring 0 32 (builtins.hashString "sha256" name) + "\n";
              defaultText = lib.literalExpression ''lib.substring 0 32 (builtins.hashString "sha256" name) + "\n"'';
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
              example = true;
              default = false;
            };

            networking = {
              useResolvConf = lib.mkEnableOption ''
                Make a resolv.conf file available in the container.

                This is required if the container wants to do DNS lookups.
              '';
              id = lib.mkOption {
                description = "Network id this container should be placed in. If null, one is picked automatically";
                type = t.nullOr t.nonEmptyStr;
                example = "192.168.1";
                default = null;
              };
              ports = {
                tcp = lib.mkOption {
                  description = "TCP Ports to open in the containers firewall";
                  type = t.listOf t.port;
                  default = [ ];
                  example = [ 8080 ];
                };
                udp = lib.mkOption {
                  type = t.listOf t.port;
                  description = "UDP Ports to open in the containers firewall";
                  default = [ ];
                  example = [ 25565 ];
                };
              };
            };

            backup = lib.mkEnableOption null // {
              default = true;
              example = false;
              description = ''
                Automatically snapshot this containers persisted subvolume.

                In addition to time-based snapshotting, a snapshot is also taken every time
                the container restarts
              '';
            };

            mounts = {
              mysql.enable = lib.mkEnableOption null // {
                description = ''
                  Mount the container's mysql data dir into persisted storage (at /persist/container/mysql).

                  If a mysql database is used within the container, you'll always want this enabled.
                '';
              };

              postgres.enable = lib.mkEnableOption null // {
                description = ''
                  Mount the container's postgresql data dir into persisted storage (at /persist/container/postgres)

                  If a postgresql database is used within the container, you'll always want this enabled.
                '';
              };

              data = {
                enable = lib.mkEnableOption null // {
                  description = ''
                    Mount (from the containers perspective) /var/lib/<containerName> into persisted storage (at /persist/container/data)

                    This is a really common pattern. A service named "example" will propably have
                    a container called "example" and place its data within a folder under /var/lib.

                    Nonetheless, verify if this is actually the case. This option is just a really stupid shortcut.
                  '';
                };
                ownerUid = lib.mkOption {
                  description = ''
                    Owner of the data dir. Since the desired user may not exist on the host, this option
                    takes an id instead of a name.

                    Be ware, that if set this is enforced and set to this value on a regular basis.

                    If set to null, the folder will at first be owned by root and its left up to the service
                    to set the correct owner.

                    The privateUsers option may interfere with this.
                  '';
                  example = lib.literalExpression "config.containers.myservice.config.users.users.myservice.uid";
                  type = t.nullOr t.int;
                  default = null;
                };
                name = lib.mkOption {
                  description = ''
                    Change the folder name under /var/lib

                    This makes this option at least a bit more versatile, and should be used
                    to achieve consistency (data dir at /persist/container/data)
                  '';
                  type = t.nonEmptyStr;
                  example = "myservice";
                  default = name;
                  defaultText = "container name";
                };
              };

              sops = {
                secrets = lib.mkOption {
                  description = ''
                    Names of sops-nix secrets to mount into the container.

                    Use `host-config.sops.secrets.my-secret.path` to access the path within the container
                  '';
                  example = lib.literalExpression ''[ "my-secret" ]'';
                  default = [ ];
                  type = t.listOf t.nonEmptyStr;
                };
                templates = lib.mkOption {
                  description = ''
                    Names of sops-nix templates to mount into the container

                    Use `host-config.sops.templates.my-template.path` to access the path within the container
                  '';
                  example = lib.literalExpression ''[ "my-template" ]'';
                  default = [ ];
                  type = t.listOf t.nonEmptyStr;
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
                        example = "/var/lib/nextcloud/data";
                        type = t.nonEmptyStr;
                      };
                      hostPath = lib.mkOption {
                        description = "Path on the host to mount from";
                        type = t.nullOr t.nonEmptyStr;
                        example = "/mnt/netapp/Nextcloud";
                        default = null;
                      };
                      isReadOnly = lib.mkOption {
                        description = ''
                          Make the mount read-only, prohibiting any modifications (from anything) from within the container
                        '';
                        type = t.bool;
                        default = true;
                      };
                      ownerUid = lib.mkOption {
                        description = ''
                          Be ware, that if set this is enforced and set to this value on a regular basis.

                          If set to null, the folder will at first be owned by root and its left up to the service
                          to set the correct owner.

                          The privateUsers option may interfere with this.
                        '';
                        type = t.nullOr t.int;
                        example = lib.literalExpression "config.users.users.nextcloud.uid";
                        default = null;
                      };
                      mode = lib.mkOption {
                        description = ''
                          Be ware, that if set this is enforced and set to this value on a regular basis.

                          If set to null, the folder will at first be owned by root and its left up to the service
                          to set the correct owner.

                          The privateUsers option may interfere with this.
                        '';
                        type = t.nonEmptyStr;
                        example = "0755";
                        default = "0700";
                      };
                    };
                  }
                );
              };
            };

            extraConfig = lib.mkOption {
              description = ''
                Extra Options/Overrides to pass to the underlying container option
              '';
              type = t.attrs;
              default = { };
              example = {
                timeoutStartSec = "15min";
              };
            };
          };
        }
      );
    in
    lib.mkOption {
      type = t.attrsOf containerType;
      description = "";
      default = { };
      example = {
        config = {
          services.postgresql.enable = true;

          system.stateVersion = "24.11";
        };

        networking.ports.tcp = [ 8000 ];
      };
    };

  config =
    let
      # ugly hack to generate a unique ip for the container
      ipPoolOf =
        name:
        lib.lists.findFirstIndex (x: x == name) (throw "unreachable") (
          lib.attrNames config.teenix.meta.services
        );

      defaultContainerNetworkId = config.teenix.config.defaultContainerNetworkId;

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

              # highlight commands
              set -u fish_color_command blue

              # dont try to speak fance keyboard protocols
              set -Ua fish_features no-keyboard-protocols
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
        typeName: names: cfg:
        lib.listToAttrs (
          lib.imap0 (i: v: {
            name = "${typeName}-${toString i}";
            value = {
              hostPath = v.path;
              mountPoint = v.path;
            };
          }) (lib.attrValues (lib.getAttrs names cfg))
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
                (sopsToMounts "sops-secret" cfg.mounts.sops.secrets config.sops.secrets)
                (sopsToMounts "sops-template" cfg.mounts.sops.templates config.sops.templates)

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

      # make sure the container restarts if its secrets change
      sops =
        let
          sopsRestartUnits =
            scope:
            lib.mkMerge (
              lib.mapAttrsToList (
                containerName: containerCfg:
                lib.genAttrs containerCfg.mounts.sops.${scope} (_: {
                  restartUnits = [ "container@${containerName}.service" ];
                })
              ) config.teenix.containers
            );
        in
        {
          secrets = sopsRestartUnits "secrets";
          templates = sopsRestartUnits "templates";
        };

      # generate the underlying container options
      containers = lib.mapAttrs mkContainer config.teenix.containers;

      # create folders in /var/log where the containers journal will be mounted
      systemd.tmpfiles.rules = lib.map (containerName: ''
        d /var/log/containers/${containerName} 0755 root systemd-journal -
      '') (lib.attrNames config.teenix.containers);

      boot.kernel.sysctl = {
        # see https://forum.proxmox.com/threads/failed-to-allocate-directory-watch-too-many-open-files.28700/
        "fs.inotify.max_user_instances" = 1024;
      };

      # create the /persist subvolume
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
          backupUnitTriggers = [ "container@${containerName}.service" ];
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
                owner = value.mounts.data.ownerUid;
                mode = "0700";
              };
            }
            (lib.mapAttrs (_: v: {
              inherit (v) mode;
              owner = v.ownerUid;
            }) (lib.filterAttrs (_: v: v.hostPath == null) value.mounts.extra))
          ];
        }
      ) config.teenix.containers;
    };
}
