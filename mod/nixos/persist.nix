{
  config,
  lib,
  utils,
  inputs,
  ...
}:
let
  cfg = config.teenix.persist;

  t = lib.types;

  defaultToString = default: x: toString (lib.defaultTo default x);

  backupSubvolumes = lib.filterAttrs (name: value: value.backup) cfg.subvolumes;

  sharedBtrbkSettings = {
    snapshot_preserve = "6h 7d 1w 1m";
    snapshot_preserve_min = "6h";
    timestamp_format = "long-iso";
  };
in
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  options.teenix.persist = {
    enable = lib.mkEnableOption ''
      A wrapper arround impermanence and btrbk. Expects a btrfs filesystem with the following layout:
      - /root <- The actual root mounted at /
      - /nix <- The root for all things nix. Mounted at /nix
      - /persist <- The root of all other persistent storage, mounted at /persist

      *Note*: For systems that use more than one (logical) drive, simply mount more
    '';
    path = lib.mkOption {
      type = t.nonEmptyStr;
      default = "/persist";
      description = ''
        The root directory for all of non generated persistent storage, except /nix and /boot.
      '';
    };
    subvolumes = lib.mkOption {
      type = t.attrsOf (
        t.submodule (
          { name, ... }:
          {
            options = {
              owner = lib.mkOption {
                type = t.nullOr (t.either t.int t.nonEmptyStr);
                default = "root";
                description = ''
                  The owner of the subvolume. If set to null, the owner will not be enforced
                '';
              };

              group = lib.mkOption {
                type = t.nullOr (t.either t.int t.nonEmptyStr);
                default = "root";
                description = ''
                  The group of the subvolume. If set to null, the group will not be enforced
                '';
              };

              mode = lib.mkOption {
                type = t.nullOr t.nonEmptyStr;
                default = "0755";
                description = "The mode of the subvolume. If set to null, the mode will not be enforced";
              };

              backup = lib.mkEnableOption "automatic snapshotting of this subvolume" // {
                default = true;
              };

              backupUnitTriggers = lib.mkOption {
                type = t.listOf utils.systemdUtils.lib.unitNameType;
                default = [ ];
                description = ''
                  List of unit names. If any of these units get started or restarted during activation, backup this subvolume.
                '';
              };

              bindMountDirectories = lib.mkEnableOption null // {
                description = ''
                  Whether all directories inside this subvolume should be bind-mounted to their respective paths in / (according to their name).
                '';
              };

              path = lib.mkOption {
                type = t.nonEmptyStr;
                default = "${config.teenix.persist.path}/${name}";
                readOnly = true;
                description = "Path this subvolume will be mounted at";
              };

              directories = lib.mkOption {
                type = t.attrsOf (
                  t.submodule {
                    options = {
                      owner = lib.mkOption {
                        type = t.nullOr (t.either t.int t.nonEmptyStr);
                        description = "Owner for this directory. If set to null, the owner will not be enforced";
                        default = "root";
                      };
                      group = lib.mkOption {
                        type = t.nullOr (t.either t.int t.nonEmptyStr);
                        description = "Group for this directory. If set to null, the group will not be enforced";
                        default = "root";
                      };
                      mode = lib.mkOption {
                        type = t.nullOr t.nonEmptyStr;
                        description = "Mode for this directory. If set to null, the mode will not be enforced";
                        default = "0755";
                      };
                    };
                  }
                );
                default = { };
                description = ''
                  Directories that should be created per default inside the subvolume
                '';
              };
            };
          }
        )
      );
      default = { };
      description = ''
        Subvolumes that should be persistent.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Default Persistent Subvolumes, these are normally needed for all Systems
    teenix.persist.subvolumes = {
      system = {
        backup = false;
        directories = {
          # The System Log should be persistent accross Reboots
          "/var/log" = { };
          "/var/lib/nixos" = { }; # For Correct User Mapping
          "/var/lib/systemd/coredump" = { };
        };
        bindMountDirectories = true;
      };
      # Storage for the SSH Host Keys - Are not part of the backup
      ssh-keys.backup = false;
    };

    # Generates the Directories inside the impermanence module
    systemd.tmpfiles.rules = lib.concatLists (
      lib.attrsets.mapAttrsToList (
        name: value:
        [
          "v ${cfg.path}/${name} ${defaultToString ":0755" value.mode} ${defaultToString ":root" value.owner} ${defaultToString ":root" value.group} -"
          (lib.mkIf value.backup "d ${value.path}/.snapshots ${value.mode} ${value.owner} ${value.group} -")
        ]
        ++ lib.attrsets.mapAttrsToList (
          n: v:
          "d '${value.path}/${n}' ${defaultToString ":0755" value.mode} ${defaultToString ":root" value.owner} ${defaultToString ":root" value.group} -"
        ) value.directories
      ) cfg.subvolumes
    );

    environment.persistence = lib.mapAttrs' (name: value: {
      name = value.path;
      value = {
        hideMounts = true;
        directories = lib.mapAttrsToList (name: value: {
          directory = name;
          user = defaultToString "root" value.owner;
          group = lib.defaultTo "root" value.group;
          mode = lib.defaultTo "0755" value.mode;
        }) value.directories;
      };
    }) (lib.attrsets.filterAttrs (name: value: value.bindMountDirectories) cfg.subvolumes);

    # Automatically snapshots the Persistent Subvolumes
    services.btrbk.instances = lib.mkMerge [
      # default instance, snapshotting everything
      {
        btrbk = {
          onCalendar = "hourly";
          settings = {
            volume = lib.attrsets.mapAttrs' (_: value: {
              name = value.path;
              value = {
                subvolume = value.path;
                snapshot_dir = ".snapshots";
              };
            }) backupSubvolumes;
          } // sharedBtrbkSettings;
        };
      }

      # seperate instances for each subvolume
      (lib.mapAttrs (_: value: {
        onCalendar = null;
        settings = {
          volume.${value.path} = {
            subvolume = value.path;
            snapshot_dir = ".snapshots";
          };
        } // sharedBtrbkSettings;
      }) backupSubvolumes)
    ];

    system.activationScripts = {
      queue-snapshots = {
        supportsDryActivation = true;
        text = # bash
          ''
            UNIT_START_FILE=/run/nixos/start-list
            UNIT_RESTART_FILE=/run/nixos/restart-list

            ACTIVATION_RESTART_FILE=$([ $NIXOS_ACTION == "dry-activate" ] && echo "/run/nixos/dry-activation-restart-list" || echo "/run/nixos/activation-restart-list")

            declare -a BACKUP_LIST=()

            ${lib.concatMapAttrsStringSep "\n" (name: value: ''
              for path in $UNIT_START_FILE $UNIT_RESTART_FILE; 
              do 
                [ ! -f $path ] && continue
                
                for unit in ${toString value.backupUnitTriggers};
                do 
                  if grep -Fx $unit $path; then
                    BACKUP_LIST+=(${name})
                  fi
                done
              done
            '') cfg.subvolumes}

            if [ ''${#BACKUP_LIST[@]} -gt 0 ]; then
              if [ $NIXOS_ACTION == "dry-activate" ]; then
                echo would snapshot the following subvolumes: ''${BACKUP_LIST[@]}
              else 
                echo snapshotting the following subvolumes: ''${BACKUP_LIST[@]}
              fi

              printf 'btrbk-%s.service\n' "''${BACKUP_LIST[@]}" >> $ACTIVATION_RESTART_FILE
            fi
          '';
      };
    };

    systemd.services = lib.mapAttrs' (name: value: {
      name = "btrbk-${name}";
      value = {
        before = value.backupUnitTriggers;
      };
    }) backupSubvolumes;

    # generate a report of what subvolumes are declared to be persistent, useful for cleaning up
    environment.etc."teenix-persistence.json".text = builtins.toJSON (
      lib.mapAttrs' (_: value: {
        name = value.path;
        value = {
          directories = lib.attrNames value.directories;
        };
      }) cfg.subvolumes
    );

    # Always exists because it is needed for SOPS and openssh
    services.openssh.hostKeys = [
      {
        bits = 4096;
        openSSHFormat = true;
        path = "${cfg.path}/ssh-keys/ssh_host_rsa_key";
        rounds = 100;
        type = "rsa";
      }
      {
        comment = "key comment";
        path = "${cfg.path}/ssh-keys/ssh_host_ed25519_key";
        rounds = 100;
        type = "ed25519";
      }
    ];
  };
}
